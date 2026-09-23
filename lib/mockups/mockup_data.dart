import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Shared mock data + interactive session for the 5 design mockups.
/// Self-contained: no package:video_player calls, runs anywhere.

class MockVideo {
  final String title;
  final String meta;
  final String duration;
  final List<Color> palette; // artwork gradient
  const MockVideo(this.title, this.meta, this.duration, this.palette);
}

const mockVideos = <MockVideo>[
  MockVideo('Sunset at the Marina', 'Travel · 1080', '4:32',
      [Color(0xFFFF9A56), Color(0xFFE24462)]),
  MockVideo('Alpine Road Trip', 'Drives · 720', '12:05',
      [Color(0xFF2EC9C9), Color(0xFF1F6FB2)]),
  MockVideo('Kitchen Stories', 'Cooking · 1080', '7:48',
      [Color(0xFFA8C686), Color(0xFFE0A458)]),
  MockVideo('Neon Nights', 'City · 4K', '3:17',
      [Color(0xFF7B5CFF), Color(0xFFE1489E)]),
  MockVideo('Quiet Forests', 'Nature · 1080', '21:10',
      [Color(0xFF5CC98F), Color(0xFF2F8F64)]),
  MockVideo('City in Motion', 'Urban · 1080', '9:02',
      [Color(0xFF5E7C9C), Color(0xFF2F4A63)]),
  MockVideo('Desert Bloom', 'Nature · 4K', '5:55',
      [Color(0xFFE0B585), Color(0xFFC25B3C)]),
  MockVideo('Deep Sea', 'Documentary · 1080', '15:40',
      [Color(0xFF1C3B6E), Color(0xFF2F8FD1)]),
  MockVideo('Autumn Avenue', 'Walks · 720', '6:21',
      [Color(0xFFC77E4A), Color(0xFF8F4D2E)]),
  MockVideo('Winter Cabin', 'Slow TV · 1080', '18:33',
      [Color(0xFF9FB8D9), Color(0xFF6A7BAE)]),
];

/// Interactive playback session shared by all mockups.
class MockSession extends ChangeNotifier {
  bool playing = false;
  double pos = 0;
  double dur = 90; // seconds
  double speed = 1.0;
  Timer? _t;
  VoidCallback? onEnded;

  void toggle() {
    playing = !playing;
    _tick();
    notifyListeners();
  }

  void _tick() {
    _t?.cancel();
    if (!playing) return;
    _t = Timer.periodic(const Duration(milliseconds: 250), (_) {
      pos += 0.25 * speed;
      if (pos >= dur) {
        pos = 0;
        playing = false;
        _t?.cancel();
        onEnded?.call();
      }
      notifyListeners();
    });
  }

  void seekTo(double v) {
    pos = v.clamp(0, dur);
    notifyListeners();
  }

  void setSpeed(double s) {
    speed = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}

String mockTime(double s) {
  final i = s.floor();
  final m = i ~/ 60;
  final sec = (i % 60).toString().padLeft(2, '0');
  return '$m:$sec';
}

/// Generative "artwork": a vertical gradient from the video palette with a
/// soft diagonal light band, plus a small play glyph. No network assets.
class MockArtwork extends StatelessWidget {
  final MockVideo video;
  final double radius;
  final bool glyph;
  const MockArtwork(
      {super.key, required this.video, this.radius = 14, this.glyph = true});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: video.palette,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -20,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            if (glyph)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedPlay,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Base class so the hub can treat all mockups uniformly.
abstract class MockStyleBase {
  String get name;
  String get tagline;
  ThemeData theme();
  Widget screen();
  List<int> thumbnails();
  Widget Function()? get navPreview => null;
}

/// Standard duration badge shared by mockups.
class MockDurationBadge extends StatelessWidget {
  final String label;
  const MockDurationBadge(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}