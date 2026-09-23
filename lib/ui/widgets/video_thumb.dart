import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/video_item.dart';
import '../../state/providers.dart';
import '../../utils/format.dart';

/// Low-res thumbnail only; shows duration badge; never blocks UI.
class VideoThumb extends ConsumerWidget {
  final VideoItem video;
  final double width;
  final double height;
  final double radius;
  const VideoThumb(
      {super.key,
      required this.video,
      this.width = 128,
      this.height = 72,
      this.radius = 12});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final repo = ref.watch(libraryRepoProvider);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: cs.surfaceContainerHighest,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (video.entityId != null)
              FutureBuilder<List<int>?>(
                future: repo.thumbBytes(video.entityId!),
                builder: (c, s) {
                  if (s.hasData && s.data != null && s.data!.isNotEmpty) {
                    return Image.memory(
                      Uint8List.fromList(s.data!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) =>
                          _fallback(cs),
                    );
                  }
                  return _fallback(cs);
                },
              )
            else
              _fallback(cs),
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formatDuration(
                      Duration(milliseconds: video.durationMs)),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(ColorScheme cs) => Container(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.play_circle_fill,
            color: cs.primary.withValues(alpha: 0.5), size: 32),
      );
}
