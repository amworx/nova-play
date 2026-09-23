import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../state/providers.dart';
import 'video_thumb.dart';

/// Compact persistent player above bottom nav. Tap opens full player.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    if (!player.hasVideo || player.current == null) {
      return const SizedBox.shrink();
    }
    // Hide on the full player route.
    final route = ModalRoute.of(context)?.settings.name;
    if (route == '/player') return const SizedBox.shrink();
    final v = player.current!;
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        child: Material(
          color: cs.surface,
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pushNamed('/player'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      VideoThumb(video: v, width: 72, height: 42, radius: 8),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(v.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600))),
                      IconButton(
                        tooltip: player.isPlaying ? 'Pause' : 'Play',
                        iconSize: 22,
                        onPressed: () => player.toggle(),
                        icon: HugeIcon(
                          icon: player.isPlaying
                              ? HugeIcons.strokeRoundedPause
                              : HugeIcons.strokeRoundedPlay,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        iconSize: 20,
                        onPressed: () =>
                            ref.read(playerProvider).stopAndClear(),
                        icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                  child: LinearProgressIndicator(
                    value: player.progress,
                    minHeight: 2.5,
                    backgroundColor:
                        cs.onSurface.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
