import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';
import '../../models/video_item.dart';
import '../../state/providers.dart';
import '../../state/player_controller.dart';
import '../../data/subtitle_parser.dart';
import '../../utils/format.dart';
import '../delete_flow.dart';
import '../widgets/queue_sheet.dart';
import '../widgets/video_thumb.dart';

/// Tideform: the playing page chosen from the Dune explorations.
/// Portrait scrolls: header · up next · video · time · transport ·
/// waveform · actions · speeds. Fullscreen follows the video: portrait clips
/// stay portrait, landscape clips rotate to landscape.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});
  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late bool _upTop;

  @override
  void initState() {
    super.initState();
    _upTop = ref.read(prefsStoreProvider).upNextOnTop();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskResume());
  }

  void _maybeAskResume() {
    final p = ref.read(playerProvider);
    if (p.pendingAskResume > 0 && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Resume playback?'),
          content: Text(
              'Continue from ${formatDuration(Duration(milliseconds: p.pendingAskResume))}?'),
          actions: [
            TextButton(
                onPressed: () {
                  p.restart();
                  Navigator.pop(context);
                },
                child: const Text('Restart')),
            FilledButton(
                onPressed: () {
                  p.resumeFromSaved();
                  Navigator.pop(context);
                },
                child: const Text('Resume')),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    // The player route goes away: restore portrait + save progress. The
    // mini player keeps playing by design.
    try {
      ref.read(playerProvider).closePlayer();
    } catch (_) {/* app teardown */}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    return PopScope(
      // Back inside fullscreen exits it first instead of popping the player.
      canPop: !player.fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && player.fullscreen) {
          player.exitFullscreen();
        }
      },
      child: Builder(builder: (context) {
        if (!player.hasVideo) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Nothing to play')),
          );
        }
        if (player.status == PlayerStatus.error) {
          return _errorPage(player);
        }
        if (player.fullscreen) return _fullscreen(player);
        // Loading is handled inside the video card: the chrome (header,
        // transport, wave) stays put so next/prev never looks like a reload.
        return _portrait(player);
      }),
    );
  }

  // ============ PORTRAIT TIDEFORM ============

  Widget _portrait(PlayerController player) {
    final cs = Theme.of(context).colorScheme;
    final v = player.current!;
    final mainSec = <Widget>[
      _VideoCard(key: ValueKey('vid-${v.id}')),
      const SizedBox(height: 8),
      const _TransportRow(),
      const SizedBox(height: 10),
    ];
    final restSec = <Widget>[
      _WaveCard(key: ValueKey('wave-${v.id}')),
      const SizedBox(height: 8),
      const _SpeedRow(),
      const SizedBox(height: 6),
      const _ExtraRow(),
    ];
    final nextSec = <Widget>[
      const _QueueHeader(),
      const SizedBox(height: 6),
      const _UpNextStrip(),
    ];
    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                  color: cs.onSurface.withValues(alpha: 0.1)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: const _ActionsRow(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            _Header(
              upTop: _upTop,
              onFlip: () async {
                final nv = !_upTop;
                setState(() => _upTop = nv);
                await ref
                    .read(prefsStoreProvider)
                    .setUpNextOnTop(nv);
              },
            ),
            const SizedBox(height: 10),
            if (_upTop) ...[...nextSec, ...mainSec, ...restSec],
            if (!_upTop) ...[...mainSec, ...restSec, ...nextSec],
          ],
        ),
      ),
    );
  }

  Widget _errorPage(PlayerController player) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(player.errorMessage ?? "Couldn't play this video.",
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to library')),
                  if (player.hasNext) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                        onPressed: () => player.next(),
                        child: const Text('Play next',
                            style:
                                TextStyle(color: Colors.white))),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ FULLSCREEN (orientation follows the video) ============

  Widget _fullscreen(PlayerController player) {
    // Only wrap a live, fully-initialized controller: a switching one is dead
    // or unborn, and VideoPlayer would throw "No active player with ID ...".
    final vc = player.status == PlayerStatus.ready && player.vc != null
        ? player.vc
        : null;
    final showUi = player.controlsVisible || !player.isPlaying;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _FsGestureLayer(
            child: Center(
              child: vc != null && vc.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: vc.value.aspectRatio == 0
                          ? 16 / 9
                          : vc.value.aspectRatio,
                      child: VideoPlayer(vc),
                    )
                  : const CircularProgressIndicator(
                      color: Colors.white),
            ),
          ),
          if (player.subtitlesEnabled &&
              player.subtitles.isNotEmpty)
            Positioned(
              left: 24,
              right: 24,
              bottom: 96,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color:
                          Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    cueAt(player.subtitles,
                            player.position.inMilliseconds) ??
                        '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.35),
                  ),
                ),
              ),
            ),
          if (player.gestureFeedback.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(14)),
                child: Text(player.gestureFeedback,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          if (showUi)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(children: [
                _fBtn(Icons.fullscreen_exit,
                    () => player.exitFullscreen()),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(player.current?.title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8)
                            ]))),
                _fBtn(
                    player.muted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    () => player.toggleMute()),
              ]),
            ),
          if (showUi)
            Positioned(
              left: 24,
              right: 24,
              bottom: 18,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Text(formatDuration(player.position),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [
                                FontFeature.tabularFigures()
                              ])),
                      Expanded(
                        child: Slider(
                          value: player.position.inMilliseconds
                              .toDouble()
                              .clamp(
                                  0,
                                  player.duration.inMilliseconds
                                      .toDouble()
                                      .clamp(1, double.infinity)),
                          max: player.duration.inMilliseconds
                              .toDouble()
                              .clamp(1, double.infinity),
                          onChanged: (v) => player.seek(Duration(
                              milliseconds: v.toInt())),
                        ),
                      ),
                      Text(formatDuration(player.duration),
                          style: TextStyle(
                              color: Colors.white.withValues(
                                  alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          _fBtn(Icons.skip_previous, () {
                            if (player.hasPrev) {
                              player.prev();
                            }
                          }),
                          const SizedBox(width: 14),
                          _fBtn(Icons.replay_10, () {
                            player.seekBy(-10000);
                          }),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () => player.toggle(),
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  shape: BoxShape.circle),
                              child: Icon(
                                  player.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28),
                            ),
                          ),
                          const SizedBox(width: 14),
                          _fBtn(Icons.forward_10, () {
                            player.seekBy(10000);
                          }),
                          const SizedBox(width: 14),
                          _fBtn(Icons.skip_next, () {
                            if (player.hasNext) {
                              player.next();
                            }
                          }),
                        ]),
                  ]),
            ),
        ],
      ),
    );
  }

  Widget _fBtn(IconData i, VoidCallback t) {
    return GestureDetector(
      onTap: t,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Center(
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8)
              ],
            ),
            child:
                Icon(i, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

// ============ HEADER ============

class _Header extends ConsumerWidget {
  final bool upTop;
  final VoidCallback onFlip;
  const _Header({required this.upTop, required this.onFlip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            await player.closePlayer();
            if (context.mounted) Navigator.pop(context);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Icon(Icons.arrow_back,
                color: cs.onSurface, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(player.current?.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onFlip,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: upTop
                  ? cs.primary
                  : cs.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Icon(Icons.swap_vert,
                color: upTop
                    ? (Theme.of(context).brightness ==
                            Brightness.dark
                        ? const Color(0xFF16130E)
                        : Colors.white)
                    : cs.onSurface,
                size: 20),
          ),
        ),
      ],
    );
  }
}

// ============ UP NEXT ============

class _QueueHeader extends ConsumerWidget {
  const _QueueHeader();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Text('Up next',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: cs.onSurface)),
      const Spacer(),
      _queueBtn(
          context,
          Icons.shuffle,
          player.shuffle,
          () => player.toggleShuffle()),
      const SizedBox(width: 6),
      _queueBtn(
          context,
          player.repeatMode == 2 ? Icons.repeat_one : Icons.repeat,
          player.repeatMode != 0,
          () => player.cycleRepeat()),
    ]);
  }

  Widget _queueBtn(
      BuildContext context, IconData i, bool on, VoidCallback t) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: t,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: on
              ? cs.primary
              : cs.primary.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(i,
            color: on
                ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF16130E)
                    : Colors.white)
                : cs.onSurface.withValues(alpha: 0.65),
            size: 18),
      ),
    );
  }
}

class _UpNextStrip extends ConsumerWidget {
  const _UpNextStrip();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final cs = Theme.of(context).colorScheme;
    final items = player.upNext.take(6).toList();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Queue is empty — this is the last video.',
            style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.55))),
      );
    }
    // Height follows the system text scale: thumbnail (56) + gap (4) +
    // two text lines. A fixed height clips (RenderFlex overflow) as soon
    // as the user picks larger text.
    final ts = MediaQuery.textScalerOf(context);
    final stripH = 64 + (ts.scale(11) + ts.scale(10)) * 1.5;
    return SizedBox(
      height: stripH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m = items[i];
          return GestureDetector(
            onTap: () => player.open(m),
            child: SizedBox(
              width: 118,
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    VideoThumb(
                        video: m,
                        width: 118,
                        height: 56,
                        radius: 10),
                    const SizedBox(height: 4),
                    Text(m.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    Text(
                        formatDuration(Duration(
                            milliseconds: m.durationMs)),
                        style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(
                                alpha: 0.5))),
                  ]),
            ),
          );
        },
      ),
    );
  }
}

// ============ VIDEO CARD + GESTURES ============

class _VideoCard extends ConsumerStatefulWidget {
  const _VideoCard({super.key});
  @override
  ConsumerState<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<_VideoCard> {
  double _dragStartX = 0;
  double _dragStartY = 0;
  int _dragStartPos = 0;
  bool _draggingSeek = false;
  bool _draggingVertical = false;
  String _dragSide = '';
  double _startBrightness = 0.5;
  double _startVolume = 0.5;

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    // Only wrap a video widget around a controller that is fully ready: a
    // switching controller is either dead (disposed) or unborn (init), and
    // mounting VideoPlayer around it throws "No active player with ID ...".
    final vc = player.status == PlayerStatus.ready ? player.vc : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Stack(fit: StackFit.expand, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: vc != null && vc.value.isInitialized
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => player.toggle(),
                      onDoubleTapDown: (d) =>
                          _doubleTap(d.globalPosition, player),
                      onHorizontalDragStart: (d) =>
                          _hStart(d.globalPosition, player),
                      onHorizontalDragUpdate: (d) =>
                          _hUpdate(d.globalPosition, player),
                      onHorizontalDragEnd: (_) => _hEnd(player),
                      onVerticalDragStart: (d) =>
                          _vStart(d.globalPosition, player),
                      onVerticalDragUpdate: (d) =>
                          _vUpdate(d.globalPosition, player),
                      onVerticalDragEnd: (_) => _vEnd(player),
                      onLongPressStart: (_) =>
                          _longStart(player),
                      onLongPressEnd: (_) => _longEnd(player),
                      // Keep the video's true aspect ratio (no stretching),
                      // letterboxed inside the card exactly like fullscreen.
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: vc.value.aspectRatio <= 0
                              ? 16 / 9
                              : vc.value.aspectRatio,
                          child: VideoPlayer(vc),
                        ),
                      ),
                    )
                  : const Center(
                      key: ValueKey('vid-loading'),
                      child: CircularProgressIndicator(
                          color: Colors.white),
                    ),
            ),
            if (player.subtitlesEnabled &&
                player.subtitles.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 52,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black
                            .withValues(alpha: 0.65),
                        borderRadius:
                            BorderRadius.circular(6)),
                    child: Text(
                      cueAt(player.subtitles,
                              player.position.inMilliseconds) ??
                          '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35),
                    ),
                  ),
                ),
              ),
            if (player.gestureFeedback.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                      color:
                          Colors.black.withValues(alpha: 0.75),
                      borderRadius:
                          BorderRadius.circular(14)),
                  child: Text(player.gestureFeedback,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            // Compact time readout overlaid on the card (no separate row).
            Positioned(
              right: 8,
              bottom: 6,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${formatDuration(player.position)} / ${formatDuration(player.duration)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [
                          FontFeature.tabularFigures()
                        ]),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _glass(
                  player.muted
                      ? Icons.volume_off
                      : Icons.volume_up,
                  () => player.toggleMute()),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: _glass(Icons.fullscreen,
                  () => player.enterFullscreen()),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _glass(IconData i, VoidCallback t) {
    return GestureDetector(
      onTap: t,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle),
        child:
            Icon(i, color: Colors.white, size: 18),
      ),
    );
  }

  bool get _gestures =>
      ref.read(prefsStoreProvider).gesturesEnabled();

  void _doubleTap(Offset pos, PlayerController player) {
    if (!_gestures) return;
    final w = MediaQuery.of(context).size.width;
    if (pos.dx < w * 0.4) {
      player.seekBy(-10000);
      player.setGestureFeedback('−10s');
    } else if (pos.dx > w * 0.6) {
      player.seekBy(10000);
      player.setGestureFeedback('+10s');
    } else {
      player.toggle();
      return;
    }
    Timer(const Duration(milliseconds: 700),
        () => player.clearGestureFeedback());
  }

  void _longStart(PlayerController player) {
    player.tempSpeed(2.0);
    player.setGestureFeedback('2× speed');
  }

  void _longEnd(PlayerController player) {
    player.endTempSpeed();
    player.clearGestureFeedback();
  }

  void _hStart(Offset pos, PlayerController player) {
    _dragStartX = pos.dx;
    _dragStartPos = player.position.inMilliseconds;
    _draggingSeek = false;
  }

  void _hUpdate(Offset pos, PlayerController player) {
    if (!_gestures) return;
    final dx = pos.dx - _dragStartX;
    if (!_draggingSeek && dx.abs() < 12) return;
    _draggingSeek = true;
    final delta = (dx * 300).toInt();
    final target = (_dragStartPos + delta)
        .clamp(0, player.duration.inMilliseconds);
    player.setGestureFeedback(
        '${delta >= 0 ? '+' : ''}${(delta / 1000).toStringAsFixed(0)}s  ·  ${formatDuration(Duration(milliseconds: target))}');
  }

  void _hEnd(PlayerController player) async {
    if (!_draggingSeek) return;
    _draggingSeek = false;
    final fb = player.gestureFeedback;
    final m = RegExp(r'([+-]?\d+)s').firstMatch(fb);
    if (m != null) {
      await player.seekBy(int.parse(m.group(1)!) * 1000);
    }
    Timer(const Duration(milliseconds: 600),
        () => player.clearGestureFeedback());
  }

  void _vStart(Offset pos, PlayerController player) async {
    _dragStartY = pos.dy;
    _draggingVertical = false;
    final w = MediaQuery.of(context).size.width;
    _dragSide = pos.dx < w / 2 ? 'left' : 'right';
    try {
      _startBrightness = await ScreenBrightness().application;
    } catch (_) {
      _startBrightness = 0.5;
    }
    try {
      _startVolume = await VolumeController.instance.getVolume();
    } catch (_) {
      _startVolume = 0.5;
    }
  }

  void _vUpdate(Offset pos, PlayerController player) async {
    if (!_gestures) return;
    final dy = _dragStartY - pos.dy;
    if (!_draggingVertical && dy.abs() < 12) return;
    _draggingVertical = true;
    final delta = (dy / 300).clamp(-1.0, 1.0);
    if (_dragSide == 'left') {
      final b = (_startBrightness + delta).clamp(0.05, 1.0);
      try {
        await ScreenBrightness()
            .setApplicationScreenBrightness(b);
      } catch (_) {}
      player.setGestureFeedback(
          'Brightness ${(b * 100).toInt()}%');
    } else {
      final v = (_startVolume + delta).clamp(0.0, 1.0);
      try {
        await VolumeController.instance.setVolume(v);
      } catch (_) {}
      player.setGestureFeedback('Volume ${(v * 100).toInt()}%');
    }
  }

  void _vEnd(PlayerController player) {
    if (!_draggingVertical) return;
    _draggingVertical = false;
    Timer(const Duration(milliseconds: 600),
        () => player.clearGestureFeedback());
  }
}

// ============ FULLSCREEN GESTURE LAYER ============
// YouTube-style controls on the fullscreen video: double-tap left/right half
// rewinds/forwards 10s, long-press plays at 2× until release, tap toggles the
// chrome, horizontal drag scrubs, vertical drag adjusts brightness (left half)
// or volume (right half). Mirrors the portrait card gestures.

class _FsGestureLayer extends ConsumerStatefulWidget {
  const _FsGestureLayer({required this.child});
  final Widget child;
  @override
  ConsumerState<_FsGestureLayer> createState() => _FsGestureLayerState();
}

class _FsGestureLayerState extends ConsumerState<_FsGestureLayer> {
  double _dragStartX = 0;
  double _dragStartY = 0;
  int _dragStartPos = 0;
  bool _draggingSeek = false;
  bool _draggingVertical = false;
  String _dragSide = '';
  double _startBrightness = 0.5;
  double _startVolume = 0.5;

  bool get _gestures => ref.read(prefsStoreProvider).gesturesEnabled();

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => player.toggleControls(),
      onDoubleTapDown: (d) => _doubleTap(d.globalPosition, player),
      onHorizontalDragStart: (d) => _hStart(d.globalPosition, player),
      onHorizontalDragUpdate: (d) => _hUpdate(d.globalPosition, player),
      onHorizontalDragEnd: (_) => _hEnd(player),
      onVerticalDragStart: (d) => _vStart(d.globalPosition, player),
      onVerticalDragUpdate: (d) => _vUpdate(d.globalPosition, player),
      onVerticalDragEnd: (_) => _vEnd(player),
      onLongPressStart: (_) => _longStart(player),
      onLongPressEnd: (_) => _longEnd(player),
      child: widget.child,
    );
  }

  void _doubleTap(Offset pos, PlayerController player) {
    if (!_gestures) return;
    final w = MediaQuery.of(context).size.width;
    if (pos.dx < w * 0.4) {
      player.seekBy(-10000);
      player.setGestureFeedback('−10s');
    } else if (pos.dx > w * 0.6) {
      player.seekBy(10000);
      player.setGestureFeedback('+10s');
    } else {
      player.toggle();
      return;
    }
    Timer(const Duration(milliseconds: 700),
        () => player.clearGestureFeedback());
  }

  void _longStart(PlayerController player) {
    if (!_gestures) return;
    player.tempSpeed(2.0);
    player.setGestureFeedback('2× speed');
  }

  void _longEnd(PlayerController player) {
    if (!_gestures) return;
    player.endTempSpeed();
    player.clearGestureFeedback();
  }

  void _hStart(Offset pos, PlayerController player) {
    _dragStartX = pos.dx;
    _dragStartPos = player.position.inMilliseconds;
    _draggingSeek = false;
  }

  void _hUpdate(Offset pos, PlayerController player) {
    if (!_gestures) return;
    final dx = pos.dx - _dragStartX;
    if (!_draggingSeek && dx.abs() < 12) return;
    _draggingSeek = true;
    final delta = (dx * 300).toInt();
    final target = (_dragStartPos + delta)
        .clamp(0, player.duration.inMilliseconds);
    player.setGestureFeedback(
        '${delta >= 0 ? '+' : ''}${(delta / 1000).toStringAsFixed(0)}s  ·  ${formatDuration(Duration(milliseconds: target))}');
  }

  void _hEnd(PlayerController player) async {
    if (!_draggingSeek) return;
    _draggingSeek = false;
    final fb = player.gestureFeedback;
    final m = RegExp(r'([+-]?\d+)s').firstMatch(fb);
    if (m != null) {
      await player.seekBy(int.parse(m.group(1)!) * 1000);
    }
    Timer(const Duration(milliseconds: 600),
        () => player.clearGestureFeedback());
  }

  void _vStart(Offset pos, PlayerController player) async {
    _dragStartY = pos.dy;
    _draggingVertical = false;
    final w = MediaQuery.of(context).size.width;
    _dragSide = pos.dx < w / 2 ? 'left' : 'right';
    try {
      _startBrightness = await ScreenBrightness().application;
    } catch (_) {
      _startBrightness = 0.5;
    }
    try {
      _startVolume = await VolumeController.instance.getVolume();
    } catch (_) {
      _startVolume = 0.5;
    }
  }

  void _vUpdate(Offset pos, PlayerController player) async {
    if (!_gestures) return;
    final dy = _dragStartY - pos.dy;
    if (!_draggingVertical && dy.abs() < 12) return;
    _draggingVertical = true;
    final delta = (dy / 300).clamp(-1.0, 1.0);
    if (_dragSide == 'left') {
      final b = (_startBrightness + delta).clamp(0.05, 1.0);
      try {
        await ScreenBrightness().setApplicationScreenBrightness(b);
      } catch (_) {}
      player.setGestureFeedback('Brightness ${(b * 100).toInt()}%');
    } else {
      final v = (_startVolume + delta).clamp(0.0, 1.0);
      try {
        await VolumeController.instance.setVolume(v);
      } catch (_) {}
      player.setGestureFeedback('Volume ${(v * 100).toInt()}%');
    }
  }

  void _vEnd(PlayerController player) {
    if (!_draggingVertical) return;
    _draggingVertical = false;
    Timer(const Duration(milliseconds: 600),
        () => player.clearGestureFeedback());
  }
}

// ============ TIME + TRANSPORT ============

class _TransportRow extends ConsumerWidget {
  const _TransportRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final cs = Theme.of(context).colorScheme;
    final onPrimary =
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF16130E)
            : Colors.white;
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _tBtn(context, Icons.skip_previous,
              player.hasPrev ? () => player.prev() : null,
              d: 40, icon: 20),
          const SizedBox(width: 6),
          _tBtn(context, Icons.replay_10,
              () => player.seekBy(-10000)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => player.toggle(),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: cs.primary
                            .withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ]),
              child: Icon(
                  player.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: onPrimary,
                  size: 28),
            ),
          ),
          const SizedBox(width: 10),
          _tBtn(context, Icons.forward_10,
              () => player.seekBy(10000)),
          const SizedBox(width: 6),
          _tBtn(context, Icons.skip_next,
              player.hasNext ? () => player.next() : null,
              d: 40, icon: 20),
        ]);
  }

  Widget _tBtn(BuildContext context, IconData i, VoidCallback? t,
      {double d = 42, double icon = 20}) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: t == null ? 0.35 : 1,
      child: GestureDetector(
        onTap: t,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
              color: cs.surface, shape: BoxShape.circle),
          child:
              Icon(i, color: cs.onSurface, size: icon),
        ),
      ),
    );
  }
}

// ============ WAVEFORM ============

class _WaveCard extends ConsumerStatefulWidget {
  const _WaveCard({super.key});
  @override
  ConsumerState<_WaveCard> createState() => _WaveCardState();
}

class _WaveCardState extends ConsumerState<_WaveCard> {
  final _waveKey = GlobalKey();
  static const bars = 56;

  double _barH(String seed, int i) {
    final h = (seed.hashCode ^ (i * 2654435761)) & 0x7fffffff;
    return 0.22 + 0.78 * ((h % 29) / 29);
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final cs = Theme.of(context).colorScheme;
    final seed = player.current?.path ?? '?';
    final f = player.duration.inMilliseconds == 0
        ? 0.0
        : player.position.inMilliseconds /
            player.duration.inMilliseconds;
    return GestureDetector(
      onHorizontalDragUpdate: (d) =>
          _seek(d.localPosition, player),
      onTapDown: (d) =>
          _seek(d.localPosition, player),
      child: Container(
        key: _waveKey,
        height: 84,
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < bars; i++)
              _bar(cs, seed, i, f),
          ],
        ),
      ),
    );
  }

  Widget _bar(
      ColorScheme cs, String seed, int i, double f) {
    final bf = i / bars;
    final near = (bf - f).abs() < 0.035;
    return Expanded(
      child: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: 1.5),
        height: 58 * _barH(seed, i),
        decoration: BoxDecoration(
          color: near
              ? cs.secondary
              : bf <= f
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  void _seek(Offset local, PlayerController player) {
    final box = _waveKey.currentContext
        ?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w = box.size.width - 28;
    final f =
        ((local.dx - 14) / w).clamp(0.0, 1.0);
    player.seek(Duration(
        milliseconds:
            (f * player.duration.inMilliseconds).toInt()));
  }
}

// ============ ACTIONS: SAVE · SHARE · RENAME · DETAILS ============

class _ActionsRow extends ConsumerWidget {
  const _ActionsRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final v = player.current!;
    final cs = Theme.of(context).colorScheme;
    final favs = ref.watch(favoritesProvider);
    final isFav = favs.contains(v.id);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _action(
            context,
            isFav ? Icons.favorite : Icons.favorite_border,
            'Save',
            isFav ? cs.primary : null, () async {
          final store = ref.read(prefsStoreProvider);
          await store.toggleFavorite(v.id);
          final cur = Set<String>.of(
              ref.read(favoritesProvider));
          if (cur.contains(v.id)) {
            cur.remove(v.id);
          } else {
            cur.add(v.id);
          }
          ref.read(favoritesProvider.notifier).state = cur;
        }),
        _action(context, Icons.queue_music, 'Queue', null,
            () => _queueSheet(context)),
        _action(context, Icons.bedtime, 'Sleep', null,
            () => _sleepSheet(context, player)),
        _action(context, Icons.ios_share, 'Share', null,
            () => _share(context, v)),
        _action(context, Icons.edit, 'Rename', null,
            () => _renameDialog(context, ref, player, v)),
        _action(context, Icons.info_outline, 'Details',
            null, () => _detailsSheet(context, player, v)),
        _action(
            context,
            Icons.delete_outline,
            'Delete',
            cs.error,
            () => _deleteDialog(context, ref, player, v),
            red: true),
      ],
    );
  }

  Widget _action(BuildContext context, IconData i,
      String label, Color? tint, VoidCallback t,
      {bool red = false}) {
    final cs = Theme.of(context).colorScheme;
    final fg = red ? cs.error : (tint ?? cs.onSurface);
    return GestureDetector(
      onTap: t,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: red
                  ? cs.error.withValues(alpha: 0.12)
                  : cs.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: cs.onSurface
                        .withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Icon(i, color: fg, size: 20),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: red
                      ? cs.error
                      : cs.onSurface
                          .withValues(alpha: 0.65))),
        ]),
      ),
    );
  }

  /// Destructive confirm → shared delete flow (controller + all provider
  /// refreshes) → leave this screen when the trash took the shown video.
  Future<void> _deleteDialog(BuildContext context, WidgetRef ref,
      PlayerController player, VideoItem v) async {
    final n = await confirmAndDelete(context, ref, [v]);
    if (n > 0 && context.mounted && !player.hasVideo) {
      Navigator.pop(context);
    }
  }

  Future<void> _share(BuildContext context, VideoItem v) async {
    if (v.path.isEmpty || !await File(v.path).exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('File is no longer available.')));
      }
      return;
    }
    try {
      await Share.shareXFiles([XFile(v.path)],
          text: v.title);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Couldn\'t share this file.')));
      }
    }
  }

  Future<void> _renameDialog(BuildContext context,
      WidgetRef ref, PlayerController player, VideoItem v) async {
    final dot = v.title.lastIndexOf('.');
    final initial =
        dot > 0 ? v.title.substring(0, dot) : v.title;
    final ctrl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename video'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
              hintText: 'Video name'),
          onSubmitted: (s) => Navigator.pop(context, s),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, ctrl.text),
              child: const Text('Rename')),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || result.trim().isEmpty) return;
    if (context.mounted) {
      await _doRename(context, ref, player, v, result.trim());
    }
  }

  Future<void> _doRename(BuildContext context, WidgetRef ref,
      PlayerController player, VideoItem v, String name) async {
    try {
      final file = File(v.path);
      if (!await file.exists()) throw 'missing';
      final dot = v.path.lastIndexOf('.');
      final ext = dot >= 0 ? v.path.substring(dot) : '';
      var base = name;
      if (ext.isNotEmpty &&
          !base.toLowerCase().endsWith(ext.toLowerCase())) {
        base += ext;
      }
      // sanitize
      base = base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final dir = v.path.substring(0, v.path.lastIndexOf('/'));
      final newPath = '$dir/$base';
      if (newPath != v.path) {
        await file.rename(newPath);
        player.renameCurrent(
            base.replaceAll(RegExp(r'\.[^.]+$'), ''),
            newPath);
        await ref
            .read(libraryProvider.notifier)
            .refresh();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Renamed.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Couldn\'t rename this file.')));
      }
    }
  }

  void _detailsSheet(BuildContext context,
      PlayerController player, VideoItem v) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v.title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const SizedBox(height: 12),
              _row(cs, 'Duration',
                  formatDuration(Duration(milliseconds: v.durationMs))),
              _row(cs, 'Size', formatBytes(v.sizeBytes)),
              if (v.resolution.isNotEmpty)
                _row(cs, 'Resolution', v.resolution),
              if (v.folder.isNotEmpty)
                _row(cs, 'Folder', v.folder),
              if (v.path.isNotEmpty)
                _row(cs, 'Location', v.path),
              if (player.subtitleLabel != null)
                _row(cs, 'Subtitles',
                    player.subtitleLabel!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(ColorScheme cs, String k, String val) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 90,
                child: Text(k,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface
                            .withValues(alpha: 0.55)))),
            Expanded(
                child: Text(val,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface))),
          ],
        ),
      );
}

// ============ SPEEDS + EXTRAS ============

class _SpeedRow extends ConsumerWidget {
  const _SpeedRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final cs = Theme.of(context).colorScheme;
    final onActive =
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF16130E)
            : Colors.white;
    return Row(
      children: [
        Icon(Icons.schedule,
            size: 18,
            color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in PlayerController.speeds) ...[
                  GestureDetector(
                    onTap: () => player.setSpeed(s),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: player.speed == s
                            ? cs.primary
                            : cs.primary
                                .withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Text('${s}×',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: player.speed == s
                                  ? onActive
                                  : cs.primary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared sheet launchers (used by both the in-row actions and the
/// subtitles mini-row) — kept at file level so any row can open them.
void _queueSheet(BuildContext context) {
  showModalBottomSheet(
      context: context, builder: (_) => const QueueSheet());
}

void _sleepSheet(BuildContext context, PlayerController player) {
  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Sleep timer',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          for (final m in [15, 30, 45, 60])
            ListTile(
              title: Text('$m minutes'),
              onTap: () {
                player.setSleepTimer(Duration(minutes: m));
                Navigator.pop(context);
              },
            ),
          ListTile(
            title: const Text('End of video'),
            onTap: () {
              player.setSleepEndOfVideo();
              Navigator.pop(context);
            },
          ),
          if (player.sleepRemaining != null)
            ListTile(
              title: const Text('Cancel timer',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                player.cancelSleepTimer();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    ),
  );
}

class _ExtraRow extends ConsumerWidget {
  const _ExtraRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (player.subtitles.isNotEmpty)
          _mini(context, Icons.closed_caption,
              player.subtitlesEnabled,
              () => player.toggleSubtitles()),
      ],
    );
  }

  Widget _mini(BuildContext context, IconData i, bool on,
      VoidCallback t) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: t,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: on
                ? cs.primary
                : cs.surface,
            shape: BoxShape.circle,
          ),
          child: Icon(i,
              size: 20,
              color: on
                  ? (Theme.of(context).brightness ==
                          Brightness.dark
                      ? const Color(0xFF16130E)
                      : Colors.white)
                  : cs.onSurface.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

}
