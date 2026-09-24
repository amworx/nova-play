import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'player_controller.dart';

/// System media notification (shade + lock screen) for Nova Play.
///
/// Same-isolate bridge: transport keys from the notification/headset go
/// straight to the [PlayerController], and every player change is mirrored
/// back as [mediaItem]/[playbackState] broadcasts. No queues are published —
/// next/previous work through the skip callbacks.
///
/// Broadcasts are throttled: per-second while playing (the OS projects
/// smooth progress from `updatePosition` + `speed` between updates) and
/// immediately on track/state/control changes.
class NovaAudioHandler extends BaseAudioHandler {
  NovaAudioHandler(this._player) {
    _player.addListener(_sync);
    _sync(force: true);
  }

  final PlayerController _player;

  String? _lastId;
  bool _lastPlaying = false;
  PlayerStatus? _lastStatus;
  double _lastSpeed = -1;
  bool _lastPrev = false;
  bool _lastNext = false;
  int _lastSecond = -1;

  static AudioProcessingState processingStateFor(PlayerStatus s) =>
      switch (s) {
        PlayerStatus.loading => AudioProcessingState.loading,
        PlayerStatus.ready => AudioProcessingState.ready,
        PlayerStatus.error => AudioProcessingState.error,
        PlayerStatus.idle => AudioProcessingState.idle,
      };

  static List<MediaControl> controlsFor({
    required bool playing,
    required bool hasPrev,
    required bool hasNext,
  }) =>
      [
        if (hasPrev) MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        if (hasNext) MediaControl.skipToNext,
      ];

  void _sync({bool force = false}) {
    final p = _player;
    final cur = p.current;
    if (cur == null) {
      // Player cleared (Close): dismiss the notification exactly once.
      // The idle broadcast alone is not enough — the service must stop.
      if (_lastId != null) {
        _lastId = null;
        _lastPlaying = false;
        mediaItem.add(null);
        playbackState.add(PlaybackState(
          controls: const [],
          processingState: AudioProcessingState.idle,
          playing: false,
        ));
        unawaited(stop());
      }
      return;
    }
    if (_lastId != cur.id) {
      _lastId = cur.id;
      mediaItem.add(MediaItem(
        id: cur.id,
        title: cur.title,
        album: cur.folder.isEmpty ? 'Nova Play' : cur.folder,
        artist: 'Nova Play',
        duration:
            p.duration.inMilliseconds > 0 ? p.duration : null,
      ));
      force = true;
    }
    final playing = p.isPlaying && p.status == PlayerStatus.ready;
    final sec = p.position.inSeconds;
    if (!force &&
        playing == _lastPlaying &&
        p.status == _lastStatus &&
        p.speed == _lastSpeed &&
        p.hasPrev == _lastPrev &&
        p.hasNext == _lastNext &&
        (sec == _lastSecond || !playing)) {
      return;
    }
    _lastPlaying = playing;
    _lastStatus = p.status;
    _lastSpeed = p.speed;
    _lastPrev = p.hasPrev;
    _lastNext = p.hasNext;
    _lastSecond = sec;
    final controls = controlsFor(
        playing: playing, hasPrev: p.hasPrev, hasNext: p.hasNext);
    playbackState.add(PlaybackState(
      controls: controls,
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices:
          List.generate(controls.length, (i) => i),
      processingState: processingStateFor(p.status),
      playing: playing,
      updatePosition: p.position,
      speed: p.speed,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) await _player.next();
  }

  @override
  Future<void> skipToPrevious() async {
    // Same rule as the UI: restart when watched a bit, else previous.
    if (_player.hasPrev) await _player.prev();
  }
}
