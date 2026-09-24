import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/video_item.dart';
import '../data/prefs_store.dart';
import '../data/subtitle_parser.dart';

enum PlayerStatus { idle, loading, ready, error }

/// Orientation lock for fullscreen from the video's own dimensions.
/// Portrait clips (taller than wide) stay portrait; everything else —
/// landscape, square, or still-unknown — rotates to landscape.
List<DeviceOrientation> preferredFullscreenOrientations(Size size) {
  if (size.width > 0 && size.height > size.width) {
    return const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ];
  }
  return const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight
  ];
}

/// Single playback brain: lifecycle-safe, disposes media correctly,
/// handles queue, resume, speed, sleep timer, subtitles, fullscreen.
class PlayerController extends ChangeNotifier with WidgetsBindingObserver {
  final PrefsStore store;
  PlayerController(this.store) {
    WidgetsBinding.instance.addObserver(this);
  }

  VideoPlayerController? _vc;
  PlayerStatus status = PlayerStatus.idle;
  String? errorMessage;
  VideoItem? current;
  List<VideoItem> queue = [];
  int queueIndex = -1;
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double speed = 1.0;
  bool fullscreen = false;
  bool controlsVisible = true;
  Timer? _hideTimer;
  Timer? _sleepTimer;
  Duration? sleepRemaining;
  String gestureFeedback = '';
  // queue modes (session-only, like YouTube)
  bool muted = false;
  bool shuffle = false;
  int repeatMode = 0; // 0 off · 1 all · 2 one
  List<int> _shuffled = []; // queue indices after current, shuffled
  // subtitles (external sidecar only)
  List<SubtitleCue> subtitles = [];
  bool subtitlesEnabled = false;
  String? subtitleLabel;

  /// Whether a video is loaded/queued. Independent of the live controller:
  /// during a next/prev switch the controller is disposed briefly, and the
  /// player must not fall back to the empty state in that window.
  bool get hasVideo => current != null;
  VideoPlayerController? get vc => _vc;
  bool _vcListenerAttached = false;
  double get progress =>
      duration.inMilliseconds == 0 ? 0 : position.inMilliseconds / duration.inMilliseconds;

  static const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  // Opens are serialized: rapid next/prev taps must never interleave two
  // open runs (the survivor would call a controller the other just disposed,
  // throwing "Bad state: No active player with ID ...").
  Future<void> _opening = Future.value();
  VideoItem? _pendingOpenVideo;
  Future<void>? _pendingOpenFuture;

  Future<void> open(VideoItem video, {List<VideoItem>? contextQueue, int startAtMs = -1}) {
    // System notification (Android 13+) needs an explicit grant; ask once on
    // first playback, never block playback on it.
    unawaited(_ensureNotificationPermission());
    // Rapid taps / auto-advance + manual tap can enqueue the same video twice
    // (queueIndex hasn't advanced yet). Drop the duplicate.
    if (_pendingOpenFuture != null &&
        _pendingOpenVideo != null &&
        _pendingOpenVideo!.id == video.id) {
      return _pendingOpenFuture!;
    }
    final run =
        _opening.then((_) => _open(video, contextQueue: contextQueue, startAtMs: startAtMs));
    // Keep the chain alive even if one open fails.
    _opening = run.then<void>((_) {}, onError: (Object e, StackTrace s) {});
    _pendingOpenVideo = video;
    _pendingOpenFuture = _opening;
    return run;
  }

  Future<void> _open(VideoItem video, {List<VideoItem>? contextQueue, int startAtMs = -1}) async {
    _pendingOpenVideo = null;
    _pendingOpenFuture = null;
    // Switch the UI to the incoming video FIRST, then tear down the old
    // controller: the chrome shows the new title with an in-card spinner
    // instead of any empty/old frame while the old one is disposed.
    _hideTimer?.cancel();
    status = PlayerStatus.loading;
    errorMessage = null;
    current = video;
    final t0 = DateTime.now();
    if (contextQueue != null && contextQueue.isNotEmpty) {
      queue = List.of(contextQueue);
      queueIndex = queue.indexWhere((e) => e.id == video.id);
      if (queueIndex < 0) {
        queue = [video, ...queue];
        queueIndex = 0;
      }
    } else if (!queue.any((e) => e.id == video.id)) {
      queue = [video, ...queue];
      queueIndex = 0;
    } else {
      queueIndex = queue.indexWhere((e) => e.id == video.id);
    }
    _rebuildShuffle();
    speed = store.defaultSpeed();
    subtitles = [];
    subtitlesEnabled = false;
    subtitleLabel = null;
    _detachListener(); // old controller must not tick/complete mid-switch
    notifyListeners();
    await _disposeVc();
    try {
      final file = File(video.path);
      if (video.path.isEmpty || !await file.exists()) {
        // Try entity path fallback? Fail gracefully with next action.
        throw 'The file is no longer available. It may have been moved or deleted.';
      }
      _vc = VideoPlayerController.file(file);
      await _vc!.initialize();
      duration = _vc!.value.duration;
      await _vc!.setPlaybackSpeed(speed);
      await _vc!.setVolume(muted ? 0.0 : 1.0);
      _vc!.addListener(_onTick);
      _vcListenerAttached = true;
      // Resume?
      int resumeMs = 0;
      if (startAtMs >= 0) {
        resumeMs = startAtMs;
      } else {
        final beh = store.resumeBehavior();
        final saved = store.resumePos(video.id);
        if (saved != null && saved > 3000 && duration.inMilliseconds > 0 &&
            saved < duration.inMilliseconds * 0.95) {
          if (beh == 'always') {
            resumeMs = saved;
          } else if (beh == 'ask') {
            resumeMs = -2; // signal UI to ask
          }
        }
      }
      status = PlayerStatus.ready;
      debugPrint('PLAY: ready ${video.title} '
          'in ${DateTime.now().difference(t0).inMilliseconds}ms');
      if (resumeMs > 0) await _vc!.seekTo(Duration(milliseconds: resumeMs));
      await _vc!.play();
      isPlaying = true;
      await WakelockPlus.enable();
      _loadSidecar(video);
      _showControlsTemporarily();
      notifyListeners();
      _pendingAskResume = resumeMs == -2 ? (store.resumePos(video.id) ?? 0) : 0;
    } catch (e) {
      status = PlayerStatus.error;
      errorMessage = _friendlyError(e);
      notifyListeners();
    }
  }

  int _pendingAskResume = 0;
  int get pendingAskResume => _pendingAskResume;
  void consumeAskResume() {
    _pendingAskResume = 0;
    notifyListeners();
  }

  Future<void> resumeFromSaved() async {
    final ms = _pendingAskResume;
    consumeAskResume();
    if (ms > 0) await seek(Duration(milliseconds: ms));
    await play();
  }

  Future<void> restart() async {
    consumeAskResume();
    await seek(Duration.zero);
    await play();
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('no longer available')) return s;
    if (s.contains('Source error') || s.contains('ExoPlayback')) {
      return "This video couldn't be played. The format may not be supported on this device.";
    }
    return "This video couldn't be played. Try another file.";
  }

  DateTime _lastUiPush = DateTime.fromMillisecondsSinceEpoch(0);
  int _lastUiSecond = -1;

  void _onTick() {
    final v = _vc?.value;
    if (v == null) return;
    position = v.position;
    duration = v.duration;
    final playing = v.isPlaying;
    // Auto-next at end.
    if (v.isCompleted) {
      _onCompleted();
      return;
    }
    // Throttle UI rebuilds: video_player fires this per frame. Pushing
    // 30-60 rebuilds/sec kills tap gestures mid-flight, drains battery,
    // and janks low-end devices. Notify on play-state flips, new seconds,
    // or 500ms heartbeats (wave playhead stays smooth).
    final now = DateTime.now();
    final sec = position.inSeconds;
    if (playing != isPlaying ||
        sec != _lastUiSecond ||
        now.difference(_lastUiPush).inMilliseconds > 500) {
      isPlaying = playing;
      _lastUiSecond = sec;
      _lastUiPush = now;
      notifyListeners();
    }
    // Persist progress periodically (every ~5s).
    if (current != null &&
        position.inMilliseconds % 5000 < 500 &&
        position.inMilliseconds > 3000) {
      store.saveProgress(current!.id, position.inMilliseconds, duration.inMilliseconds);
    }
  }

  Future<void> _onCompleted() async {
    if (current != null) {
      await store.saveProgress(current!.id, duration.inMilliseconds, duration.inMilliseconds);
    }
    if (_sleepEndOfVideo) {
      await pause();
      cancelSleepTimer();
      return;
    }
    if (repeatMode == 2) {
      await seek(Duration.zero);
      await play();
      return;
    }
    if (hasNext) {
      await next();
    } else {
      isPlaying = false;
      await WakelockPlus.disable();
      notifyListeners();
    }
  }

  Future<void> _loadSidecar(VideoItem video) async {
    try {
      if (video.path.isEmpty) return;
      final base = video.path.replaceAll(RegExp(r'\.[^.]+$'), '');
      for (final ext in ['.srt', '.vtt']) {
        final f = File('$base$ext');
        if (await f.exists()) {
          final content = await f.readAsString();
          final cues = parseSubtitles(content);
          if (cues.isNotEmpty) {
            subtitles = cues;
            subtitleLabel = ext.substring(1).toUpperCase();
            return;
          }
        }
      }
    } catch (_) {/* never break playback */}
  }

  // --- basic transport ---
  Future<void> play() async {
    await _safeCall(() async => _vc?.play());
    isPlaying = true;
    _showControlsTemporarily();
    notifyListeners();
  }

  Future<void> pause() async {
    if (current != null) {
      await store.saveProgress(
          current!.id, position.inMilliseconds, duration.inMilliseconds);
    }
    await _safeCall(() async => _vc?.pause());
    isPlaying = false;
    notifyListeners();
  }

  Future<void> toggle() async {
    debugPrint('TAPCHECK toggle called, isPlaying=$isPlaying');
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration d) async {
    await _safeCall(() async => _vc?.seekTo(d));
    _showControlsTemporarily(brief: true);
  }

  Future<void> seekBy(int deltaMs) async {
    debugPrint('TAPCHECK seekBy $deltaMs');
    final target = Duration(
        milliseconds:
            (position.inMilliseconds + deltaMs).clamp(0, duration.inMilliseconds));
    await seek(target);
  }

  Future<void> setSpeed(double s) async {
    speed = s;
    await _safeCall(() async => _vc?.setPlaybackSpeed(s));
    await store.setDefaultSpeed(s);
    notifyListeners();
  }

  // --- queue ---
  /// Videos after the current one, in play order (shuffled or natural).
  List<VideoItem> get upNext {
    if (queueIndex < 0 || queue.isEmpty) return [];
    if (shuffle) {
      return [
        for (final i in _shuffled)
          if (i >= 0 && i < queue.length) queue[i]
      ];
    }
    return queue.sublist(queueIndex + 1);
  }

  VideoItem? get nextUp => upNext.isEmpty ? null : upNext.first;
  bool get hasNext => repeatMode == 1 ? queue.isNotEmpty : upNext.isNotEmpty;
  bool get hasPrev => queueIndex > 0;

  void _rebuildShuffle() {
    _shuffled = [
      for (var i = 0; i < queue.length; i++)
        if (i != queueIndex) i
    ]..shuffle();
    // keep only videos after current for the strip; full list for wrap
  }

  Future<void> toggleShuffle() async {
    debugPrint('TAPCHECK toggleShuffle called');
    shuffle = !shuffle;
    if (shuffle) _rebuildShuffle();
    notifyListeners();
  }

  Future<void> cycleRepeat() async {
    debugPrint('TAPCHECK cycleRepeat -> ${(repeatMode + 1) % 3}');
    repeatMode = (repeatMode + 1) % 3;
    notifyListeners();
  }

  Future<void> toggleMute() async {
    debugPrint('TAPCHECK toggleMute');
    muted = !muted;
    await _safeCall(() async => _vc?.setVolume(muted ? 0.0 : 1.0));
    notifyListeners();
  }

  Future<void> next() async {
    debugPrint('TAPCHECK next');
    if (shuffle) {
      // drop stale entries (e.g. after strip-tap opens)
      _shuffled.removeWhere((i) => i == queueIndex);
      if (_shuffled.isNotEmpty) {
        await open(queue[_shuffled.removeAt(0)]);
        return;
      }
      if (repeatMode == 1 && queue.isNotEmpty) {
        _rebuildShuffle();
        if (_shuffled.isNotEmpty) {
          await open(queue[_shuffled.removeAt(0)]);
        }
      }
      return;
    }
    if (queueIndex >= 0 && queueIndex < queue.length - 1) {
      await open(queue[queueIndex + 1]);
      return;
    }
    if (repeatMode == 1 && queue.isNotEmpty) {
      await open(queue.first);
    }
  }

  Future<void> prev() async {
    debugPrint('TAPCHECK prev');
    if (position.inMilliseconds > 3000) {
      await restart();
      return;
    }
    if (!hasPrev) {
      await restart();
      return;
    }
    await open(queue[queueIndex - 1]);
  }

  /// Reflect a file rename without losing place in queue.
  void renameCurrent(String title, String path) {
    if (current == null) return;
    final updated = VideoItem(
      id: current!.id,
      title: title,
      path: path,
      entityId: current!.entityId,
      durationMs: current!.durationMs,
      sizeBytes: current!.sizeBytes,
      width: current!.width,
      height: current!.height,
      dateModifiedMs: DateTime.now().millisecondsSinceEpoch,
      folder: current!.folder,
    );
    current = updated;
    queue = [
      for (final e in queue) e.id == updated.id ? updated : e
    ];
    notifyListeners();
  }

  // 2× preview while long-pressing (doesn't change saved speed).
  double? _savedSpeed;
  Future<void> tempSpeed(double s) async {
    debugPrint('TAPCHECK tempSpeed $s');
    _savedSpeed ??= speed;
    speed = s;
    await _vc?.setPlaybackSpeed(s);
    notifyListeners();
  }

  Future<void> endTempSpeed() async {
    debugPrint('TAPCHECK endTempSpeed');
    final s = _savedSpeed ?? store.defaultSpeed();
    _savedSpeed = null;
    speed = s;
    await _vc?.setPlaybackSpeed(s);
    notifyListeners();
  }

  void enqueue(VideoItem v) {
    if (queue.any((e) => e.id == v.id)) return;
    queue.add(v);
    notifyListeners();
  }

  void removeFromQueue(int i) {
    if (i < 0 || i >= queue.length) return;
    queue.removeAt(i);
    if (i < queueIndex) queueIndex--;
    if (i == queueIndex) queueIndex = queueIndex.clamp(0, queue.isEmpty ? 0 : queue.length - 1);
    notifyListeners();
  }

  /// Permanently delete a video from the device (its file/MediaStore asset
  /// ends up in the system trash/recently-deleted — recoverable there).
  ///
  /// Cleans every persisted reference (favorites, all playlists,
  /// resume/history, queue) and, when the deleted item was the one playing,
  /// advances to the next item or closes the player if the queue empties.
  /// Ref-free on purpose: the caller (screen, which owns a Ref) refreshes
  /// the in-memory favorites/library providers. Returns success.
  Future<bool> deleteVideo(VideoItem v) async =>
      await deleteVideos([v]) == 1;

  /// Delete many videos with a SINGLE system consent: one `deleteWithIds`
  /// call for every MediaStore asset (Android shows one trash dialog instead
  /// of one per video), then per-item cleanup. Returns the deleted count.
  Future<int> deleteVideos(List<VideoItem> items) async {
    if (items.isEmpty) return 0;
    final withId = items
        .where((v) => v.entityId != null && v.entityId!.isNotEmpty)
        .toList();
    final pathOnly = items
        .where((v) =>
            (v.entityId == null || v.entityId!.isEmpty) &&
            v.path.isNotEmpty)
        .toList();
    final deletedEntityIds = <String>{};
    final deletedPathIds = <String>{};
    try {
      if (withId.isNotEmpty) {
        final res = await PhotoManager.editor
            .deleteWithIds(withId.map((v) => v.entityId!).toList());
        deletedEntityIds.addAll(res);
      }
    } catch (_) {}
    for (final v in pathOnly) {
      try {
        final f = File(v.path);
        if (await f.exists()) {
          await f.delete();
          deletedPathIds.add(v.id);
        }
      } catch (_) {}
    }
    if (deletedEntityIds.isEmpty && deletedPathIds.isEmpty) return 0;
    final deleted = items
        .where((v) =>
            deletedEntityIds.contains(v.entityId) ||
            deletedPathIds.contains(v.id))
        .toList();

    // Drop them from the queue wherever they sit (shuffled or not).
    for (var i = queue.length - 1; i >= 0; i--) {
      if (deleted.any((d) => d.id == queue[i].id)) removeFromQueue(i);
    }
    // Advance/close FIRST so closePlayer()'s own progress-write for a
    // deleted item is overwritten by the cleanup below, not re-added.
    final wasCurrent = deleted.any((d) => d.id == current?.id);
    if (wasCurrent) {
      if (hasNext) {
        await next();
      } else {
        await closePlayer();
      }
    }

    // Persisted stores.
    for (final d in deleted) {
      await store.removeFavorite(d.id);
      await store.removeProgress(d.id);
      await store.removeFromAllPlaylists(d.id);
    }
    return deleted.length;
  }

  void reorderQueue(int oldI, int newI) {
    if (oldI < 0 || oldI >= queue.length || newI < 0 || newI > queue.length) return;
    if (newI > oldI) newI--;
    final item = queue.removeAt(oldI);
    queue.insert(newI, item);
    if (current != null) {
      queueIndex = queue.indexWhere((e) => e.id == current!.id);
    }
    notifyListeners();
  }

  void clearQueue({bool keepCurrent = true}) {
    if (keepCurrent && current != null) {
      queue = [current!];
      queueIndex = 0;
    } else {
      queue = [];
      queueIndex = -1;
    }
    notifyListeners();
  }

  // --- controls auto-hide ---
  void pokeControls() {
    controlsVisible = true;
    notifyListeners();
    _showControlsTemporarily();
  }

  /// Tap on the fullscreen video: show the chrome, or hide it if visible
  /// (YouTube-style).
  void toggleControls() {
    debugPrint('TAPCHECK toggleControls visible=$controlsVisible');
    if (controlsVisible) {
      _hideTimer?.cancel();
      controlsVisible = false;
      notifyListeners();
    } else {
      pokeControls();
    }
  }

  void _showControlsTemporarily({bool brief = false}) {
    controlsVisible = true;
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: brief ? 2 : 4), () {
      if (isPlaying) {
        controlsVisible = false;
        notifyListeners();
      }
    });
  }

  void setGestureFeedback(String s) {
    gestureFeedback = s;
    notifyListeners();
  }

  void clearGestureFeedback() {
    gestureFeedback = '';
    notifyListeners();
  }

  Future<void> toggleSubtitles() async {
    subtitlesEnabled = !subtitlesEnabled;
    notifyListeners();
  }

  // --- sleep timer ---
  void setSleepTimer(Duration d) {
    _sleepTimer?.cancel();
    _sleepEndOfVideo = false;
    sleepRemaining = d;
    _sleepTimer = Timer(d, () async {
      await pause();
      sleepRemaining = null;
      notifyListeners();
    });
    notifyListeners();
  }

  bool _sleepEndOfVideo = false;
  void setSleepEndOfVideo() {
    _sleepTimer?.cancel();
    _sleepEndOfVideo = true;
    sleepRemaining = const Duration(seconds: -1); // sentinel: end of video
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepEndOfVideo = false;
    sleepRemaining = null;
    notifyListeners();
  }

  bool get sleepEndOfVideo => _sleepEndOfVideo;

  // --- fullscreen / orientation ---
  /// Enters fullscreen following the video: a vertical clip stays in
  /// portrait instead of being force-flipped sideways; landscape (or a
  /// not-yet-measured) video rotates to landscape like before.
  Future<void> enterFullscreen() async {
    fullscreen = true;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(
        preferredFullscreenOrientations(_videoSize()));
    notifyListeners();
  }

  /// Live video dimensions, or [Size.zero] when nothing is measurable yet.
  Size _videoSize() {
    final vc = _vc;
    if (vc == null || !vc.value.isInitialized) return Size.zero;
    return vc.value.size;
  }

  static bool _notifAsked = false;

  /// One-shot POST_NOTIFICATIONS grant for the media notification.
  /// Denied/permanently-denied just means no notification — playback is
  /// unaffected, and the system never re-prompts on its own.
  Future<void> _ensureNotificationPermission() async {
    try {
      if (_notifAsked) return;
      _notifAsked = true;
      final st = await Permission.notification.status;
      if (st.isDenied) await Permission.notification.request();
    } catch (_) {}
  }

  Future<void> exitFullscreen() async {
    fullscreen = false;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    notifyListeners();
  }

  Future<void> closePlayer() async {
    if (current != null) {
      await store.saveProgress(
          current!.id, position.inMilliseconds, duration.inMilliseconds);
    }
    if (fullscreen) await exitFullscreen();
    // Keep mini-player: don't dispose, just pause? Spec mini-player continues.
    notifyListeners();
  }

  Future<void> stopAndClear() async {
    await _disposeVc();
    current = null;
    status = PlayerStatus.idle;
    isPlaying = false;
    position = Duration.zero;
    duration = Duration.zero;
    await WakelockPlus.disable();
    if (fullscreen) await exitFullscreen();
    notifyListeners();
  }

  Future<void> _disposeVc() async {
    _detachListener();
    await _safePause();
    await _vc?.dispose();
    _vc = null;
  }

  /// Pause the live controller without risking an uncaught platform error.
  /// Skips the pause entirely while a switch is in progress (the incoming
  /// player may not be registered yet, and pausing is pointless anyway).
  Future<void> _safePause() async {
    if (status == PlayerStatus.loading || _vc == null) return;
    try {
      await _vc!.pause();
    } catch (_) {}
  }

  /// Run a platform call wrapped so a disposed/vanished player can never
  /// surface an uncaught StateError ("No active player with ID ...").
  Future<void> _safeCall(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {/* UI keeps working; state stays consistent */}
  }

  void _detachListener() {
    if (_vcListenerAttached) {
      _vc?.removeListener(_onTick);
      _vcListenerAttached = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause on background; release nothing so resume is instant.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (isPlaying) {
        _safePause();
        isPlaying = false;
        if (current != null) {
          store.saveProgress(
              current!.id, position.inMilliseconds, duration.inMilliseconds);
        }
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _sleepTimer?.cancel();
    unawaited(_disposeVc().catchError((Object e, StackTrace s) {}));
    WakelockPlus.disable();
    super.dispose();
  }
}
