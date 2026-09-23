import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/library_repository.dart';
import '../data/prefs_store.dart';
import '../models/playlist.dart';
import '../models/video_item.dart';
import 'player_controller.dart';

final sharedPrefsProvider =
    Provider<SharedPreferences>((_) => throw UnimplementedError());

final prefsStoreProvider = Provider<PrefsStore>((ref) {
  return PrefsStore(ref.watch(sharedPrefsProvider));
});

final libraryRepoProvider = Provider<LibraryRepository>((_) => LibraryRepository());

/// Library state: cached first for instant paint, then fresh MediaStore scan.
final libraryProvider =
    StateNotifierProvider<LibraryNotifier, AsyncValue<List<VideoItem>>>(
        (ref) => LibraryNotifier(ref));

class LibraryNotifier extends StateNotifier<AsyncValue<List<VideoItem>>> {
  final Ref ref;
  LibraryNotifier(this.ref) : super(const AsyncValue.loading()) {
    final cached = ref.read(prefsStoreProvider).cachedLibrary();
    if (cached.isNotEmpty) state = AsyncValue.data(cached);
    refresh();
  }

  Future<LibraryResult> refresh({bool prompt = false}) async {
    state = state.when(
      data: (d) => d.isEmpty ? const AsyncValue.loading() : AsyncValue.data(d),
      error: (_, __) => const AsyncValue.loading(),
      loading: () => const AsyncValue.loading(),
    );
    final repo = ref.read(libraryRepoProvider);
    final res = await repo.load(prompt: prompt);
    if (res.status == LibraryStatus.ok) {
      state = AsyncValue.data(res.videos);
      await ref.read(prefsStoreProvider).cacheLibrary(res.videos);
      _lastStatus = LibraryStatus.ok;
      _lastMessage = null;
      _lastLimited = res.limited;
    } else if (res.status == LibraryStatus.permissionRequired ||
        res.status == LibraryStatus.permissionDenied) {
      // Permission gates always win over a stale cache: showing old videos
      // while access is revoked only leads to "looks loaded, plays nothing".
      state = const AsyncValue.data([]);
      _lastStatus = res.status;
      _lastMessage = res.message;
      _lastLimited = false;
    } else {
      // Transient failure: keep the cache, surface the status separately.
      if (state.hasValue && state.value!.isNotEmpty) {
        _lastStatus = res.status;
      } else {
        state = AsyncValue.data([]);
      }
      _lastStatus = res.status;
      _lastMessage = res.message;
    }
    // NOTE: no ref.invalidate(libraryStatusProvider) here — it watches
    // libraryProvider and rebuilds on state change; invalidating it from
    // inside this notifier throws CircularDependencyError and kills the app.
    return res;
  }

  LibraryStatus _lastStatus = LibraryStatus.ok;
  String? _lastMessage;
  bool _lastLimited = false;
  LibraryStatus get lastStatus => _lastStatus;
  String? get lastMessage => _lastMessage;
  bool get lastLimited => _lastLimited;
}

final libraryStatusProvider = Provider<(LibraryStatus, String?)>((ref) {
  final n = ref.watch(libraryProvider.notifier);
  // trigger rebuild on library change
  ref.watch(libraryProvider);
  return (n.lastStatus, n.lastMessage);
});

final playerProvider = ChangeNotifierProvider<PlayerController>((ref) {
  return PlayerController(ref.watch(prefsStoreProvider));
});

// Favorites / history / playlists as simple providers invalidated on change.
final favoritesProvider = StateProvider<Set<String>>((ref) {
  return ref.watch(prefsStoreProvider).favorites();
});

/// Theme mode as reactive state: prefsStoreProvider is a plain Provider, so
/// watching it never rebuilds when SharedPreferences values change. The
/// settings sheet writes both the persisted value and this provider.
final themeModeProvider = StateProvider<String>((ref) {
  return ref.watch(prefsStoreProvider).themeMode();
});

final historyProvider =
    StateProvider<Map<String, Map<String, int>>>((ref) {
  return ref.watch(prefsStoreProvider).history();
});

final playlistsProvider =
    StateNotifierProvider<PlaylistNotifier, List<Playlist>>(
        (ref) => PlaylistNotifier(ref));

class PlaylistNotifier extends StateNotifier<List<Playlist>> {
  final Ref ref;
  PlaylistNotifier(this.ref)
      : super(ref.read(prefsStoreProvider).playlists());

  Future<void> _save() =>
      ref.read(prefsStoreProvider).savePlaylists(state);

  Future<void> create(String name) async {
    state = [
      ...state,
      Playlist(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name)
    ];
    await _save();
  }

  Future<void> rename(String id, String name) async {
    state = [for (final p in state) if (p.id == id) p.copyWith(name: name) else p];
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _save();
  }

  Future<void> addVideo(String id, VideoItem v) async {
    state = [
      for (final p in state)
        if (p.id == id && !p.videos.any((e) => e.id == v.id))
          p.copyWith(videos: [...p.videos, v])
        else
          p
    ];
    await _save();
  }

  Future<void> removeVideo(String id, String videoId) async {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(
              videos: p.videos.where((e) => e.id != videoId).toList())
        else
          p
    ];
    await _save();
  }

  Future<void> reorder(String id, int oldI, int newI) async {
    final p = state.firstWhere((e) => e.id == id);
    final list = List<VideoItem>.of(p.videos);
    if (newI > oldI) newI--;
    final item = list.removeAt(oldI);
    list.insert(newI, item);
    state = [for (final e in state) if (e.id == id) e.copyWith(videos: list) else e];
    await _save();
  }
}

final searchQueryProvider = StateProvider<String>((_) => '');
