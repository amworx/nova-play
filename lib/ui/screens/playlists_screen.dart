import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../state/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/video_tile.dart';
import '../widgets/video_thumb.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createDialog(context, ref),
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 20),
        label: const Text('New playlist'),
      ),
      body: playlists.isEmpty
          ? const EmptyState(
              icon: HugeIcons.strokeRoundedPlaylist01,
              title: 'No playlists yet',
              message: 'Group videos for movie nights, courses, or trips.',
            )
          : ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (_, i) {
                final p = playlists[i];
                return Dismissible(
                  key: ValueKey(p.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete,
                        color: Colors.white),
                  ),
                  onDismissed: (_) => ref
                      .read(playlistsProvider.notifier)
                      .remove(p.id),
                  child: ListTile(
                    leading: p.videos.isNotEmpty
                        ? VideoThumb(
                            video: p.videos.first,
                            width: 56,
                            height: 56,
                            radius: 12)
                        : Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const HugeIcon(
                                icon: HugeIcons
                                    .strokeRoundedPlaylist01),
                          ),
                    title: Text(p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle:
                        Text('${p.videos.length} videos'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'rename') {
                          _renameDialog(context, ref, p.id, p.name);
                        } else if (v == 'play' &&
                            p.videos.isNotEmpty) {
                          ref.read(playerProvider).open(
                              p.videos.first,
                              contextQueue: p.videos);
                          Navigator.of(context)
                              .pushNamed('/player');
                        } else if (v == 'delete') {
                          ref
                              .read(playlistsProvider.notifier)
                              .remove(p.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'play', child: Text('Play')),
                        PopupMenuItem(
                            value: 'rename',
                            child: Text('Rename')),
                        PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete')),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                PlaylistDetail(id: p.id))),
                  ),
                );
              },
            ),
    );
  }

  void _createDialog(BuildContext context, WidgetRef ref) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
            controller: c,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'e.g. Road trip')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (c.text.trim().isNotEmpty) {
                  ref
                      .read(playlistsProvider.notifier)
                      .create(c.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text('Create')),
        ],
      ),
    );
  }

  void _renameDialog(
      BuildContext context, WidgetRef ref, String id, String cur) {
    final c = TextEditingController(text: cur);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename playlist'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (c.text.trim().isNotEmpty) {
                  ref
                      .read(playlistsProvider.notifier)
                      .rename(id, c.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text('Save')),
        ],
      ),
    );
  }
}

class PlaylistDetail extends ConsumerWidget {
  final String id;
  const PlaylistDetail({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final p =
        playlists.where((e) => e.id == id).firstOrNull;
    if (p == null) {
      return Scaffold(
          appBar: AppBar(), body: const Text('Playlist deleted'));
    }
    final history = ref.watch(historyProvider);
    final lib = ref.watch(libraryProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          if (p.videos.isNotEmpty)
            IconButton(
              tooltip: 'Play all',
              onPressed: () {
                ref
                    .read(playerProvider)
                    .open(p.videos.first, contextQueue: p.videos);
                Navigator.of(context).pushNamed('/player');
              },
              icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedPlay),
            ),
          IconButton(
            tooltip: 'Add videos',
            onPressed: () =>
                _addVideosSheet(context, ref, p.id, lib),
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01),
          ),
        ],
      ),
      body: p.videos.isEmpty
          ? EmptyState(
              icon: HugeIcons.strokeRoundedPlaylist01,
              title: 'Empty playlist',
              message: 'Add videos from your library.',
              actionLabel: 'Add videos',
              onAction: () =>
                  _addVideosSheet(context, ref, p.id, lib),
            )
          : ReorderableListView.builder(
              itemCount: p.videos.length,
              onReorder: (o, n) => ref
                  .read(playlistsProvider.notifier)
                  .reorder(p.id, o, n),
              itemBuilder: (_, i) {
                final v = p.videos[i];
                return Dismissible(
                  key: ValueKey('${p.id}_${v.id}_$i'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                      color:
                          Theme.of(context).colorScheme.error),
                  onDismissed: (_) => ref
                      .read(playlistsProvider.notifier)
                      .removeVideo(p.id, v.id),
                  child: VideoTile(
                    key: ValueKey('tile_${v.id}_$i'),
                    video: v,
                    queueContext: p.videos,
                    progressMs: history[v.id]?['pos'],
                  ),
                );
              },
            ),
    );
  }

  void _addVideosSheet(BuildContext context, WidgetRef ref,
      String pid, List lib) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (c, sc) => ListView.builder(
          controller: sc,
          itemCount: lib.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(lib[i].title,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01, size: 20),
            onTap: () {
              ref
                  .read(playlistsProvider.notifier)
                  .addVideo(pid, lib[i]);
              Navigator.pop(c);
            },
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
