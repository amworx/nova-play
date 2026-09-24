import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_item.dart';
import '../state/providers.dart';

/// Shared delete flow for lists AND the player: confirm → delete →
/// refresh everything → feedback. Returns the deleted count.
///
/// Refresh covers all in-memory state (favorites, history, playlists,
/// library rescan) so a deleted video vanishes from every list immediately.
/// `playlistsProvider` is safe to invalidate here (plain state rebuilt from
/// the store — unlike `prefsStoreProvider`, which must never be invalidated
/// mid-playback).
Future<int> confirmAndDelete(
    BuildContext context, WidgetRef ref, List<VideoItem> items) async {
  if (items.isEmpty) return 0;
  final cs = Theme.of(context).colorScheme;
  final single = items.length == 1;
  final yes = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(single ? 'Delete video?' : 'Delete ${items.length} videos?'),
      content: Text(single
          ? '"${items.first.title}" will be moved to trash and removed from '
              'your library, favorites, playlists and queue.'
          : '${items.length} videos will be moved to trash and removed from '
              'your library, favorites, playlists and queue. One system confirmation covers them all.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: cs.error, foregroundColor: cs.onError),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete')),
      ],
    ),
  );
  if (yes != true || !context.mounted) return 0;

  final player = ref.read(playerProvider);
  final n = await player.deleteVideos(items);
  if (!context.mounted) return n;
  if (n > 0) {
    final ids = items.map((v) => v.id).toSet();
    final favs = Set<String>.of(ref.read(favoritesProvider))..removeAll(ids);
    ref.read(favoritesProvider.notifier).state = favs;
    ref.invalidate(historyProvider);
    ref.invalidate(playlistsProvider);
    await ref.read(libraryProvider.notifier).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(single ? 'Video deleted.' : '$n videos deleted.')));
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Couldn't delete (system trash refused).")));
  }
  return n;
}
