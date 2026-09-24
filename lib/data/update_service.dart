import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// In-app updates for sideloaded builds, served from GitHub Releases.
///
/// Flow: Settings → Check for updates → Download & install. The download is
/// performed by `ota_update`, which fires the Android install intent
/// automatically the moment the APK finishes downloading — the user just
/// confirms "Install" in the system dialog.
///
/// Playback and the library stay offline-first: network is used only here,
/// on demand, and every failure maps to a human-readable message.
const updateRepoOwner = 'amworx';
const updateRepoName = 'nova-play';
const updateCheckUrl =
    'https://api.github.com/repos/$updateRepoOwner/$updateRepoName/releases/latest';

/// Fixed internal filename so repeated downloads overwrite instead of piling up.
const updateApkFilename = 'nova-play-update.apk';

/// Describes one installable GitHub release.
class ReleaseInfo {
  const ReleaseInfo({
    required this.tag,
    required this.version,
    required this.build,
    required this.apkUrl,
    required this.apkName,
    required this.notes,
  });

  /// Raw release tag, e.g. `v1.0.1`.
  final String tag;

  /// Tag without leading `v` / build suffix, e.g. `1.0.1`.
  final String version;

  /// Build number parsed from `+N` suffix when present, else 0.
  final int build;

  /// Direct download URL of the APK asset.
  final String apkUrl;

  /// Asset filename, e.g. `nova-play-v1.0.1.apk`.
  final String apkName;

  /// Release notes (may be empty).
  final String notes;
}

enum UpdateCheckStatus {
  available,
  upToDate,
  offline,
  noReleases,
  rateLimited,
  error,
}

class UpdateCheckResult {
  const UpdateCheckResult(this.status, this.message, [this.release]);

  final UpdateCheckStatus status;
  final String message;
  final ReleaseInfo? release;
}

/// UI phases for the Settings updates section. Ephemeral on purpose: update
/// state is session-only, so no prefs keys and no plain-Provider pitfalls.
enum UpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  installing,
  error,
}

class UpdateState {
  const UpdateState({
    required this.phase,
    this.currentVersion = '',
    this.release,
    this.progress = 0,
    this.message = '',
    this.installPermissionNeeded = false,
  });

  const UpdateState.idle() : this(phase: UpdatePhase.idle);

  final UpdatePhase phase;
  final String currentVersion;
  final ReleaseInfo? release;
  final int progress;
  final String message;
  final bool installPermissionNeeded;

  UpdateState copyWith({
    UpdatePhase? phase,
    String? currentVersion,
    ReleaseInfo? Function()? release,
    int? progress,
    String? message,
    bool? installPermissionNeeded,
  }) {
    return UpdateState(
      phase: phase ?? this.phase,
      currentVersion: currentVersion ?? this.currentVersion,
      release: release == null ? this.release : release(),
      progress: progress ?? this.progress,
      message: message ?? this.message,
      installPermissionNeeded:
          installPermissionNeeded ?? this.installPermissionNeeded,
    );
  }
}

/// `1.0.1`, `v1.0.1`, `1.0.1+4` → `[1, 0, 1]`. Never throws.
List<int> parseVersionParts(String v) {
  var s = v.trim();
  if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
  s = s.split('+').first;
  if (s.isEmpty) return const [0];
  return s.split('.').map((p) {
    final digits = p.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }).toList();
}

/// Build number from `1.0.1+42`, else 0. Never throws.
int parseBuildNumber(String v) {
  final plus = v.trim().split('+');
  if (plus.length < 2) return 0;
  return int.tryParse(plus.last.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
}

/// Compares [current] (e.g. `1.0.0+1`) against [latestTag] (e.g. `v1.0.1`).
/// Returns >0 when the tag is newer, 0 when equal, <0 when older.
int compareVersions(String current, String latestTag) {
  final a = parseVersionParts(current);
  final b = parseVersionParts(latestTag);
  for (var i = 0; i < 3; i++) {
    final av = i < a.length ? a[i] : 0;
    final bv = i < b.length ? b[i] : 0;
    if (bv != av) return bv.compareTo(av);
  }
  return parseBuildNumber(latestTag).compareTo(parseBuildNumber(current));
}

/// True when [latestTag] is a newer release than [currentVersion].
bool isUpdateAvailable(String currentVersion, String latestTag) =>
    compareVersions(currentVersion, latestTag) > 0;

/// Extracts the installable release from a `releases/latest` JSON object.
/// Returns null when there is no tag or no `.apk` asset. Never throws.
ReleaseInfo? parseLatestRelease(Map<String, dynamic> json) {
  final tag = (json['tag_name'] as String?)?.trim();
  if (tag == null || tag.isEmpty) return null;
  final rawAssets = json['assets'];
  if (rawAssets is! List) return null;

  Map<String, dynamic>? picked;
  for (final item in rawAssets) {
    if (item is! Map) continue;
    final asset = Map<String, dynamic>.from(item);
    final name = (asset['name'] as String?) ?? '';
    final url = (asset['browser_download_url'] as String?) ?? '';
    if (!name.toLowerCase().endsWith('.apk') || url.isEmpty) continue;
    picked ??= asset;
    if (name.contains(updateRepoName)) picked = asset;
    if (name == '$updateRepoName-$tag.apk') break;
  }
  if (picked == null) return null;

  final version = tag.replaceAll(RegExp(r'^[vV]'), '').split('+').first;
  return ReleaseInfo(
    tag: tag,
    version: version.isEmpty ? tag : version,
    build: parseBuildNumber(tag),
    apkUrl: picked['browser_download_url'] as String,
    apkName: (picked['name'] as String?) ?? updateApkFilename,
    notes: (json['body'] as String?)?.trim() ?? '',
  );
}

/// Checks GitHub for a newer release. Every outcome — including offline,
/// rate limits, and malformed responses — maps to a readable message.
class UpdateService {
  UpdateService({this.checkUrl = updateCheckUrl, HttpClient? client})
      : _clientFactory = client == null
            ? HttpClient.new
            : (() => client);

  final String checkUrl;
  final HttpClient Function() _clientFactory;

  static const _timeout = Duration(seconds: 12);

  Future<UpdateCheckResult> checkForUpdate(String currentVersion) async {
    final client = _clientFactory()
      ..connectionTimeout = _timeout;
    try {
      final request = await client
          .getUrl(Uri.parse(checkUrl))
          .timeout(_timeout, onTimeout: () => throw TimeoutException('check'));
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
        ..set(HttpHeaders.userAgentHeader, '$updateRepoName-updater');
      final response =
          await request.close().timeout(_timeout, onTimeout: () {
        throw TimeoutException('check');
      });
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout, onTimeout: () => throw TimeoutException('check'));

      if (response.statusCode == 404) {
        return const UpdateCheckResult(UpdateCheckStatus.noReleases,
            'No releases published yet. Check back later.');
      }
      if (response.statusCode == 403 || response.statusCode == 429) {
        return const UpdateCheckResult(UpdateCheckStatus.rateLimited,
            'Too many checks right now. Try again in a little while.');
      }
      if (response.statusCode != 200) {
        return UpdateCheckResult(UpdateCheckStatus.error,
            'Update check failed (server ${response.statusCode}). Try again later.');
      }

      Map<String, dynamic> json;
      try {
        final decoded = jsonDecode(body);
        if (decoded is! Map) throw const FormatException('not an object');
        json = Map<String, dynamic>.from(decoded);
      } catch (_) {
        return const UpdateCheckResult(UpdateCheckStatus.error,
            'Update response was unreadable. Try again later.');
      }

      final release = parseLatestRelease(json);
      if (release == null) {
        return const UpdateCheckResult(UpdateCheckStatus.noReleases,
            'The latest release has no installable file yet.');
      }
      if (isUpdateAvailable(currentVersion, release.tag)) {
        return UpdateCheckResult(UpdateCheckStatus.available,
            'Version ${release.tag} is available.', release);
      }
      return UpdateCheckResult(UpdateCheckStatus.upToDate,
          'You are on the latest version.');
    } on SocketException {
      return const UpdateCheckResult(UpdateCheckStatus.offline,
          'You appear to be offline. Connect and try again.');
    } on TimeoutException {
      return const UpdateCheckResult(UpdateCheckStatus.error,
          'Update check timed out. Try again.');
    } catch (_) {
      return const UpdateCheckResult(UpdateCheckStatus.error,
          'Something went wrong while checking. Try again.');
    } finally {
      client.close(force: true);
    }
  }
}
