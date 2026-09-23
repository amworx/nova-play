import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../state/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/video_tile.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider).toLowerCase().trim();
    final lib = ref.watch(libraryProvider);
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBar(
              hintText: 'Search file or folder name',
              leading: const HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01, size: 20),
              trailing: query.isEmpty
                  ? null
                  : [
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: () => ref
                            .read(searchQueryProvider.notifier)
                            .state = '',
                        icon: const HugeIcon(
                            icon:
                                HugeIcons.strokeRoundedCancel01,
                            size: 20),
                      )
                    ],
              onChanged: (v) => ref
                  .read(searchQueryProvider.notifier)
                  .state = v,
            ),
          ),
          Expanded(
            child: lib.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => const EmptyState(
                icon: HugeIcons.strokeRoundedAlert02,
                title: 'Search unavailable',
                message: 'Library failed to load.',
              ),
              data: (videos) {
                if (query.isEmpty) {
                  return const EmptyState(
                    icon: HugeIcons.strokeRoundedSearch01,
                    title: 'Find any video',
                    message:
                        'Type a file or folder name — results update as you type.',
                  );
                }
                final results = videos
                    .where((v) =>
                        v.title.toLowerCase().contains(query) ||
                        v.folder.toLowerCase().contains(query))
                    .toList();
                if (results.isEmpty) {
                  return EmptyState(
                    icon:
                        HugeIcons.strokeRoundedSearchRemove,
                    title: 'No results for "$query"',
                    message:
                        'Try a different spelling or shorter word.',
                    actionLabel: 'Clear search',
                    onAction: () => ref
                        .read(searchQueryProvider.notifier)
                        .state = '',
                  );
                }
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) => VideoTile(
                    video: results[i],
                    queueContext: results,
                    progressMs: history[results[i].id]?['pos'],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
