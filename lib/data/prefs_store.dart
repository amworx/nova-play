import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/video_item.dart';

/// Local-first persistence: favorites, history, resume, playlists, settings.
class PrefsStore {
  final SharedPreferences prefs;
  PrefsStore(this.prefs);

  static const _fav = 'favorites_v1';
  static const _hist = 'history_v1'; // id -> {pos, dur, ts}
  static const _pls = 'playlists_v1';
  static const _theme = 'theme_mode'; // system/light/dark
  static const _speed = 'default_speed';
  static const _resume = 'resume_behavior'; // always/ask/never
  static const _gestures = 'gestures_enabled';

  Set<String> favorites() => prefs.getStringList(_fav)?.toSet() ?? {};
  Future<void> toggleFavorite(String id) async {
    final s = favorites();
    if (s.contains(id)) {
      s.remove(id);
    } else {
      s.add(id);
    }
    await prefs.setStringList(_fav, s.toList());
  }

  /// Remove [id] from favorites (no-op if absent).
  Future<void> removeFavorite(String id) async {
    final s = favorites();
    if (s.remove(id)) {
      await prefs.setStringList(_fav, s.toList());
    }
  }

  /// Remove [id] from the saved-progress history (no-op if absent).
  Future<void> removeProgress(String id) async {
    final h = history();
    if (h.remove(id) == null) return;
    await prefs.setString(_hist, jsonEncode(h));
  }

  /// Remove [id] from every playlist that contains it.
  Future<void> removeFromAllPlaylists(String id) async {
    final pls = playlists();
    var changed = false;
    final out = <Playlist>[];
    for (final p in pls) {
      if (p.videos.any((v) => v.id == id)) {
        out.add(p.copyWith(
            videos: p.videos.where((v) => v.id != id).toList()));
        changed = true;
      } else {
        out.add(p);
      }
    }
    if (changed) await savePlaylists(out);
  }

  Map<String, Map<String, int>> history() {
    final raw = prefs.getString(_hist);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return m.map((k, v) {
        final e = Map<String, dynamic>.from(v as Map);
        return MapEntry(k, {
          'pos': (e['pos'] as num?)?.toInt() ?? 0,
          'dur': (e['dur'] as num?)?.toInt() ?? 0,
          'ts': (e['ts'] as num?)?.toInt() ?? 0,
        });
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> saveProgress(String id, int posMs, int durMs) async {
    // Don't resume effectively-completed videos (>95%).
    if (durMs > 0 && posMs >= durMs * 0.95) {
      final h = history()..remove(id);
      await prefs.setString(_hist, jsonEncode(h));
      return;
    }
    if (posMs < 3000) return; // ignore trivial starts
    final h = history();
    h[id] = {'pos': posMs, 'dur': durMs, 'ts': DateTime.now().millisecondsSinceEpoch};
    // cap history at 100 entries
    if (h.length > 100) {
      final sorted = h.entries.toList()
        ..sort((a, b) => (a.value['ts'] ?? 0).compareTo(b.value['ts'] ?? 0));
      for (var i = 0; i < h.length - 100; i++) {
        h.remove(sorted[i].key);
      }
    }
    await prefs.setString(_hist, jsonEncode(h));
  }

  Future<void> clearHistory() => prefs.remove(_hist);

  List<Playlist> playlists() {
    final raw = prefs.getString(_pls);
    if (raw == null || raw.isEmpty) return [];
    try {
      final l = jsonDecode(raw) as List;
      return l
          .map((e) => Playlist.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlaylists(List<Playlist> list) =>
      prefs.setString(_pls, jsonEncode(list.map((e) => e.toJson()).toList()));

  String themeMode() => prefs.getString(_theme) ?? 'system';
  Future<void> setThemeMode(String v) => prefs.setString(_theme, v);

  double defaultSpeed() => prefs.getDouble(_speed) ?? 1.0;
  Future<void> setDefaultSpeed(double v) => prefs.setDouble(_speed, v);

  String resumeBehavior() => prefs.getString(_resume) ?? 'ask';
  Future<void> setResumeBehavior(String v) => prefs.setString(_resume, v);

  bool gesturesEnabled() => prefs.getBool(_gestures) ?? true;
  Future<void> setGesturesEnabled(bool v) => prefs.setBool(_gestures, v);

  static const _upNextTop = 'upnext_on_top';
  bool upNextOnTop() => prefs.getBool(_upNextTop) ?? true;
  Future<void> setUpNextOnTop(bool v) =>
      prefs.setBool(_upNextTop, v);

  int? resumePos(String id) => history()[id]?['pos'];

  // Cache last-known library snapshot soFirst paint is instant offline.
  static const _libCache = 'library_cache_v1';
  List<VideoItem> cachedLibrary() {
    final raw = prefs.getString(_libCache);
    if (raw == null || raw.isEmpty) return [];
    try {
      final l = jsonDecode(raw) as List;
      return l
          .map((e) => VideoItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cacheLibrary(List<VideoItem> items) => prefs.setString(
      _libCache, jsonEncode(items.take(500).map((e) => e.toJson()).toList()));
}
