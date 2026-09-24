import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/update_service.dart';
import '../../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(prefsStoreProvider);
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _group('Playback'),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedGauge),
            title: const Text('Default speed'),
            subtitle: Text('${store.defaultSpeed()}×'),
            onTap: () => _speedSheet(context, ref),
          ),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedPlay),
            title: const Text('Resume behavior'),
            subtitle: Text(_resumeLabel(store.resumeBehavior())),
            onTap: () => _resumeSheet(context, ref),
          ),
          SwitchListTile(
            secondary: const HugeIcon(
                icon: HugeIcons.strokeRoundedTouch01),
            title: const Text('Gesture controls'),
            subtitle: const Text('Swipe to seek, sides for volume/brightness'),
            value: store.gesturesEnabled(),
            onChanged: (v) async {
              await store.setGesturesEnabled(v);
              ref.invalidate(historyProvider);
              (context as Element).markNeedsBuild();
            },
          ),
          SwitchListTile(
            secondary: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowUpDown),
            title: const Text('Up next on top'),
            subtitle: const Text(
                'Show the queue above the player instead of below'),
            value: store.upNextOnTop(),
            onChanged: (v) async {
              await store.setUpNextOnTop(v);
              (context as Element).markNeedsBuild();
            },
          ),
          _group('Library'),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh01),
            title: const Text('Rescan library'),
            subtitle: const Text(
                'Also lets you select more videos'),
            onTap: () => ref
                .read(libraryProvider.notifier)
                .refresh(prompt: true),
          ),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedClock01),
            title: const Text('Clear history'),
            subtitle: Text('${history.length} entries'),
            onTap: () async {
              await store.clearHistory();
              ref.invalidate(historyProvider);
            },
          ),
          _group('Appearance'),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedMoon01),
            title: const Text('Theme'),
            subtitle: Text(ref.watch(themeModeProvider)),
            onTap: () => _themeSheet(context, ref),
          ),
          _group('Updates'),
          const _UpdatesSection(),
          _group('About'),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle),
            title: Text(ref.watch(appVersionProvider).when(
                  data: (p) => 'Nova Play ${p.version}',
                  loading: () => 'Nova Play',
                  error: (_, __) => 'Nova Play',
                )),
            subtitle: const Text(
                'Offline-first local video player. Your videos never leave this device.'),
          ),
        ],
      ),
    );
  }

  Widget _group(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
      );

  String _resumeLabel(String v) => switch (v) {
        'always' => 'Always resume',
        'never' => 'Always restart',
        _ => 'Ask me',
      };

  void _speedSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
              .map((s) => ListTile(
                    title: Text('${s}×'),
                    onTap: () async {
                      await ref
                          .read(prefsStoreProvider)
                          .setDefaultSpeed(s);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _resumeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in [
              ('ask', 'Ask me'),
              ('always', 'Always resume'),
              ('never', 'Always restart')
            ])
              ListTile(
                title: Text(e.$2),
                onTap: () async {
                  await ref
                      .read(prefsStoreProvider)
                      .setResumeBehavior(e.$1);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _themeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in ['system', 'light', 'dark'])
              ListTile(
                title: Text(m[0].toUpperCase() + m.substring(1)),
                trailing:
                    ref.watch(themeModeProvider) == m
                        ? Icon(Icons.check,
                            color: Theme.of(context)
                                .colorScheme
                                .primary)
                        : null,
                onTap: () async {
                  await ref
                      .read(prefsStoreProvider)
                      .setThemeMode(m);
                  ref.read(themeModeProvider.notifier).state = m;
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// App updates from GitHub Releases: check → download → the Android installer
/// opens automatically once the download finishes. Session-only state lives in
/// [updateStateProvider]; nothing here touches SharedPreferences.
class _UpdatesSection extends ConsumerStatefulWidget {
  const _UpdatesSection();

  @override
  ConsumerState<_UpdatesSection> createState() => _UpdatesSectionState();
}

class _UpdatesSectionState extends ConsumerState<_UpdatesSection> {
  StreamSubscription<OtaEvent>? _sub;

  @override
  void dispose() {
    // Stops UI events only — the explicit Cancel button stops a download.
    _sub?.cancel();
    super.dispose();
  }

  String _installedVersion(PackageInfo? pkg) =>
      pkg == null ? '' : '${pkg.version}+${pkg.buildNumber}';

  Future<PackageInfo?> _loadPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  Future<void> _check() async {
    final cur = ref.read(updateStateProvider);
    if (cur.phase == UpdatePhase.checking ||
        cur.phase == UpdatePhase.downloading) {
      return;
    }
    PackageInfo? pkg = ref.read(appVersionProvider).valueOrNull;
    pkg ??= await _loadPackageInfo();
    if (!mounted) return;
    if (pkg == null) {
      ref.read(updateStateProvider.notifier).state = cur.copyWith(
        phase: UpdatePhase.error,
        message: 'Could not read the installed version. Try again.',
        installPermissionNeeded: false,
      );
      return;
    }
    final version = _installedVersion(pkg);
    ref.read(updateStateProvider.notifier).state = cur.copyWith(
      phase: UpdatePhase.checking,
      currentVersion: version,
      message: 'Checking for updates…',
      installPermissionNeeded: false,
    );
    final res = await UpdateService().checkForUpdate(version);
    if (!mounted) return;
    ref.read(updateStateProvider.notifier).state = switch (res.status) {
      UpdateCheckStatus.available => UpdateState(
          phase: UpdatePhase.available,
          currentVersion: version,
          release: res.release,
          message: res.message,
        ),
      UpdateCheckStatus.upToDate => UpdateState(
          phase: UpdatePhase.upToDate,
          currentVersion: version,
          message: res.message,
        ),
      _ => UpdateState(
          phase: UpdatePhase.error,
          currentVersion: version,
          message: res.message,
        ),
    };
  }

  Future<void> _download() async {
    final cur = ref.read(updateStateProvider);
    final release = cur.release;
    if (release == null ||
        cur.phase == UpdatePhase.downloading ||
        cur.phase == UpdatePhase.checking) {
      return;
    }
    // Android 8+ blocks installs from unknown sources until the user allows
    // this app. Ask first so a refusal explains itself instead of surfacing
    // as a cryptic failure after a full download.
    var permission = await Permission.requestInstallPackages.status;
    if (!permission.isGranted) {
      permission = await Permission.requestInstallPackages.request();
    }
    if (!mounted) return;
    if (!permission.isGranted) {
      ref.read(updateStateProvider.notifier).state = cur.copyWith(
        phase: UpdatePhase.error,
        installPermissionNeeded: true,
        message:
            'Nova Play is not allowed to install updates. Allow “Install unknown apps” for Nova Play, then try again.',
      );
      return;
    }
    PackageInfo? pkg = ref.read(appVersionProvider).valueOrNull;
    pkg ??= await _loadPackageInfo();
    if (!mounted) return;
    final authority = pkg == null
        ? 'com.example.video_player.ota_update_provider'
        : '${pkg.packageName}.ota_update_provider';
    await _sub?.cancel();
    ref.read(updateStateProvider.notifier).state = cur.copyWith(
      phase: UpdatePhase.downloading,
      progress: 0,
      message: 'Downloading ${release.tag}…',
      installPermissionNeeded: false,
    );
    _sub = OtaUpdate()
        .execute(
      release.apkUrl,
      destinationFilename: updateApkFilename,
      androidProviderAuthority: authority,
    )
        .listen(_onOtaEvent);
  }

  void _onOtaEvent(OtaEvent event) {
    if (!mounted) return;
    final notifier = ref.read(updateStateProvider.notifier);
    final cur = ref.read(updateStateProvider);
    switch (event.status) {
      case OtaStatus.DOWNLOADING:
        final p = int.tryParse(event.value ?? '');
        notifier.state = cur.copyWith(
          phase: UpdatePhase.downloading,
          progress: p == null ? cur.progress : p.clamp(0, 100),
          message: 'Downloading ${cur.release?.tag ?? 'update'}…',
        );
      case OtaStatus.INSTALLING:
        // Download finished and the system installer is now open.
        notifier.state = cur.copyWith(
          phase: UpdatePhase.installing,
          progress: 100,
          message:
              'Download complete. The installer is open — tap Install to finish.',
        );
      case OtaStatus.ALREADY_RUNNING_ERROR:
        notifier.state = cur.copyWith(
          phase: UpdatePhase.error,
          message: 'A download is already running.',
        );
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        notifier.state = cur.copyWith(
          phase: UpdatePhase.error,
          installPermissionNeeded: true,
          message:
              'Nova Play is not allowed to install updates. Allow “Install unknown apps” for Nova Play, then try again.',
        );
      case OtaStatus.DOWNLOAD_ERROR:
        notifier.state = cur.copyWith(
          phase: UpdatePhase.error,
          message: 'Download failed. Check your connection and try again.',
        );
      case OtaStatus.CANCELED:
        notifier.state = cur.copyWith(
          phase:
              cur.release == null ? UpdatePhase.idle : UpdatePhase.available,
          progress: 0,
          message: 'Download canceled.',
        );
      case OtaStatus.CHECKSUM_ERROR:
      case OtaStatus.INSTALLATION_ERROR:
      case OtaStatus.INTERNAL_ERROR:
      case OtaStatus.INSTALLATION_DONE:
        notifier.state = cur.copyWith(
          phase: UpdatePhase.error,
          message: event.status == OtaStatus.INSTALLATION_DONE
              ? 'Update installed. Reopen Nova Play if it did not restart itself.'
              : 'Something went wrong during the update. Try again.',
        );
    }
  }

  Future<void> _cancelDownload() async {
    try {
      await OtaUpdate().cancel();
    } catch (_) {
      // No active download — the CANCELED event (or its absence) decides.
    }
  }

  void _showNotes(ReleaseInfo release) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('What’s new in ${release.tag}'),
        content: SingleChildScrollView(
          child: Text(release.notes.isEmpty
              ? 'No release notes for this version.'
              : release.notes),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _download();
            },
            child: const Text('Download & install'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateStateProvider);
    final installed = ref.watch(appVersionProvider).when(
          data: _installedVersion,
          loading: () => state.currentVersion,
          error: (_, _) => state.currentVersion,
        );

    final subtitle = switch (state.phase) {
      UpdatePhase.idle => installed.isEmpty
          ? 'Check for new versions'
          : '$installed · Tap to check for updates',
      UpdatePhase.checking => 'Checking for updates…',
      UpdatePhase.upToDate => state.currentVersion.isEmpty
          ? 'You are up to date'
          : '${state.currentVersion} · You are up to date',
      UpdatePhase.available =>
        '${state.release?.tag ?? 'New version'} available · Tap to download',
      UpdatePhase.downloading => 'Downloading… ${state.progress}%',
      UpdatePhase.installing =>
        'Download complete — the installer is open',
      UpdatePhase.error => state.message,
    };

    final VoidCallback? onTap = switch (state.phase) {
      UpdatePhase.checking || UpdatePhase.downloading => null,
      UpdatePhase.available => _download,
      _ => _check,
    };

    final Widget trailing = switch (state.phase) {
      UpdatePhase.checking => const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            semanticsLabel: 'Checking for updates',
          ),
        ),
      UpdatePhase.downloading => IconButton(
          tooltip: 'Cancel download',
          onPressed: _cancelDownload,
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
        ),
      UpdatePhase.available => const HugeIcon(
          icon: HugeIcons.strokeRoundedDownload01),
      UpdatePhase.error when state.installPermissionNeeded => IconButton(
          tooltip: 'Open app settings',
          onPressed: openAppSettings,
          icon: const HugeIcon(icon: HugeIcons.strokeRoundedSettings01),
        ),
      _ => const HugeIcon(icon: HugeIcons.strokeRoundedRefresh01),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const HugeIcon(
              icon: HugeIcons.strokeRoundedSystemUpdate01),
          title: const Text('App updates'),
          subtitle: Text(subtitle),
          trailing: trailing,
          onTap: onTap,
        ),
        if (state.phase == UpdatePhase.downloading)
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 8),
            child: LinearProgressIndicator(
              value: state.progress / 100,
              semanticsLabel:
                  'Update download progress, ${state.progress} percent',
            ),
          ),
        if (state.phase == UpdatePhase.available && state.release != null)
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle),
            title: Text('What’s new in ${state.release!.tag}'),
            subtitle: Text(
              state.release!.notes.isEmpty
                  ? 'Tap to view details.'
                  : state.release!.notes,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _showNotes(state.release!),
          ),
        if (state.phase == UpdatePhase.error &&
            state.installPermissionNeeded)
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedSettings01),
            title: const Text('Open app settings'),
            subtitle: const Text(
                'Allow “Install unknown apps” for Nova Play'),
            onTap: openAppSettings,
          ),
      ],
    );
  }
}
