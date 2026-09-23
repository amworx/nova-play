import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../state/providers.dart';
import '../../models/video_item.dart';
import '../widgets/empty_state.dart';
import '../widgets/video_tile.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs =
      TabController(length: 4, vsync: this);

  @override
  Widget build(BuildContext context) {
    final lib = ref.watch(libraryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Rescan',
            onPressed: () =>
                ref.read(libraryProvider.notifier).refresh(),
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh01),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () =>
                Navigator.of(context).pushNamed('/settings'),
            icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedSettings01),
          ),
        ],
        bottom: TabBar(
          controller: tabs,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Recent'),
            Tab(text: 'Favorites'),
            Tab(text: 'Folders'),
          ],
        ),
      ),
      body: lib.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: HugeIcons.strokeRoundedAlert02,
          title: 'Something went wrong',
          message: 'Pull down or tap retry to scan again.',
          actionLabel: 'Retry',
          onAction: () =>
              ref.read(libraryProvider.notifier).refresh(),
        ),
        data: (videos) {
          if (videos.isEmpty) {
            return const EmptyState(
              icon: HugeIcons.strokeRoundedVideoOff,
              title: 'No videos yet',
              message:
                  'Add video files to your device, then rescan the library.',
            );
          }
          return TabBarView(
            controller: tabs,
            children: [
              _list(context, ref, videos),
              _list(context, ref,
                  List.of(videos)..sort((a, b) => b.dateModifiedMs.compareTo(a.dateModifiedMs))),
              _favorites(context, ref, videos),
              _folders(context, ref, videos),
            ],
          );
        },
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<VideoItem> videos) {
    final history = ref.watch(historyProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(libraryProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (_, i) => VideoTile(
          video: videos[i],
          queueContext: videos,
          progressMs: history[videos[i].id]?['pos'],
        ),
      ),
    );
  }

  Widget _favorites(
      BuildContext context, WidgetRef ref, List<VideoItem> videos) {
    final favs = ref.watch(favoritesProvider);
    final list = videos.where((v) => favs.contains(v.id)).toList();
    if (list.isEmpty) {
      return const EmptyState(
        icon: HugeIcons.strokeRoundedFavourite,
        title: 'No favorites yet',
        message: 'Tap the menu on any video and choose Toggle favorite.',
      );
    }
    return _list(context, ref, list);
  }

  Widget _folders(
      BuildContext context, WidgetRef ref, List<VideoItem> videos) {
    final folders = <String, List<VideoItem>>{};
    for (final v in videos) {
      folders.putIfAbsent(
          v.folder.isEmpty ? 'Videos' : v.folder, () => []).add(v);
    }
    final keys = folders.keys.toList()..sort();
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final k = keys[i];
        final list = folders[k]!;
        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const HugeIcon(
                icon: HugeIcons.strokeRoundedFolder01),
          ),
          title: Text(k,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${list.length} videos'),
          trailing: const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01, size: 20),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _FolderDetail(
                  name: k, videos: list))),
        );
      },
    );
  }
}

class _FolderDetail extends ConsumerWidget {
  final String name;
  final List<VideoItem> videos;
  const _FolderDetail({required this.name, required this.videos});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (_, i) => VideoTile(
          video: videos[i],
          queueContext: videos,
          progressMs: history[videos[i].id]?['pos'],
        ),
      ),
    );
  }
}
