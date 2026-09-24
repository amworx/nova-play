import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/video_item.dart';
import '../../state/providers.dart';
import '../../utils/format.dart';
import '../delete_flow.dart';
import 'video_thumb.dart';

/// Compact list row: thumbnail-dominant, title + short metadata, overflow menu.
/// Long-press enters bulk selection (see [librarySelectionProvider]); while
/// selecting, taps toggle instead of opening the player.
class VideoTile extends ConsumerWidget {
  final VideoItem video;
  final List<VideoItem> queueContext;
  final int? progressMs;
  const VideoTile(
      {super.key, required this.video, required this.queueContext, this.progressMs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sel = ref.watch(librarySelectionProvider);
    final selecting = sel.isNotEmpty;
    final selected = sel.contains(video.id);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (selecting) {
          final next = Set<String>.of(sel);
          if (selected) {
            next.remove(video.id);
          } else {
            next.add(video.id);
          }
          ref.read(librarySelectionProvider.notifier).state = next;
          return;
        }
        ref.read(playerProvider).open(video, contextQueue: queueContext);
        Navigator.of(context).pushNamed('/player');
      },
      onLongPress: () {
        final next = Set<String>.of(sel)..add(video.id);
        ref.read(librarySelectionProvider.notifier).state = next;
      },
      child: Container(
        decoration: selected
            ? BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Stack(
                children: [
                  VideoThumb(
                      video: video, width: 128, height: 72, radius: 12),
                  if (selected)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: cs.surface, width: 2),
                        ),
                        child: Icon(Icons.check,
                            color: cs.onPrimary, size: 14),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDuration(Duration(milliseconds: video.durationMs))}  ·  ${video.folder.isEmpty ? formatBytes(video.sizeBytes) : video.folder}',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                    if (progressMs != null &&
                        progressMs! > 0 &&
                        video.durationMs > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: (progressMs! / video.durationMs)
                                .clamp(0.0, 1.0),
                            backgroundColor:
                                cs.onSurface.withValues(alpha: 0.12),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    cs.primary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              VideoOverflowMenu(video: video),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoOverflowMenu extends ConsumerWidget {
  final VideoItem video;
  const VideoOverflowMenu({super.key, required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      iconSize: 20,
      tooltip: 'Video options',
      onSelected: (v) async {
        final player = ref.read(playerProvider);
        final store = ref.read(prefsStoreProvider);
        if (v == 'queue') {
          player.enqueue(video);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to queue')));
        } else if (v == 'fav') {
          await store.toggleFavorite(video.id);
          ref.invalidate(favoritesProvider);
        } else if (v == 'play') {
          await player.open(video, contextQueue: [video]);
          if (context.mounted) Navigator.of(context).pushNamed('/player');
        } else if (v == 'delete') {
          await confirmAndDelete(context, ref, [video]);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'play', child: Text('Play')),
        const PopupMenuItem(value: 'queue', child: Text('Add to queue')),
        const PopupMenuItem(value: 'fav', child: Text('Toggle favorite')),
        PopupMenuItem(
            value: 'delete',
            child: Text('Delete',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error))),
      ],
    );
  }
}
