import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../state/providers.dart';
import '../../data/library_repository.dart';
import '../../models/video_item.dart';
import '../../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/video_thumb.dart';

/// Folio home: wordmark + mood chips, one lead story with a resume
/// ring, then a numbered index. Mono's bones, Hearth's soul.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _mood = 0; // 0 all · 1 continue · 2 favorites

  @override
  void initState() {
    super.initState();
    // Debug-only: auto-open the player with the first library video so
    // device tap tests have a deterministic target screen. Enable with
    // `--dart-define=AUTOPLAY=true`. Never active in release builds.
    if (const bool.fromEnvironment('AUTOPLAY') && kDebugMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoPlay());
    }
  }

  Future<void> _autoPlay() async {
    List<VideoItem>? list;
    for (var i = 0; i < 60 && list == null; i++) {
      final lib = ref.read(libraryProvider);
      if (lib.hasValue && lib.value!.isNotEmpty) {
        list = lib.value;
        break;
      }
      // If the scan is blocked (e.g. permission revoked by a fresh test
      // install), retry it a few times: the adb `pm grant` lands mid-run.
      if (i % 6 == 3) {
        final status = ref.read(libraryStatusProvider).$1;
        debugPrint('AUTOPLAY: library status=$status, retrying scan');
        await ref.read(libraryProvider.notifier).refresh();
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    if (!mounted) return;
    if (list == null) {
      debugPrint('AUTOPLAY: no videos in library');
      return;
    }
    debugPrint('AUTOPLAY: opening ${list!.first.title}');
    _open(context, ref, list!.first, list!);
  }

  @override
  Widget build(BuildContext context) {
    final lib = ref.watch(libraryProvider);
    final status = ref.watch(libraryStatusProvider);
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: cs.primary,
          onRefresh: () => ref.read(libraryProvider.notifier).refresh(),
          child: lib.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              icon: HugeIcons.strokeRoundedAlert02,
              title: 'Something went wrong',
              message: 'We couldn\'t load your videos. Pull to try again.',
              actionLabel: 'Retry',
              onAction: () =>
                  ref.read(libraryProvider.notifier).refresh(),
            ),
            data: (videos) {
              if (videos.isEmpty) {
                return _firstRunState(context, ref, status);
              }
              final history = ref.watch(historyProvider);
              final favs = ref.watch(favoritesProvider);
              final continued =
                  _continueWatching(videos, history);
              final shown = _mood == 1
                  ? continued
                  : _mood == 2
                      ? videos
                          .where((v) => favs.contains(v.id))
                          .toList()
                      : videos;
              final lead = continued.isNotEmpty
                  ? continued.first
                  : videos.first;
              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _header(context, ref, videos.length, favs.length),
                  if (_mood != 1) ...[
                    _leadStory(context, ref, lead, history, videos),
                    const SizedBox(height: 18),
                  ],
                  _rule(onSurface),
                  const SizedBox(height: 12),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Row(
                      children: [
                        Text(
                            _mood == 0
                                ? 'Index'
                                : _mood == 1
                                    ? 'Continue'
                                    : 'Favorites',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: onSurface)),
                        const Spacer(),
                        Text(
                            '${shown.length.toString().padLeft(2, '0')} — ${shown.length == 1 ? 'ENTRY' : 'ENTRIES'}',
                            style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w800,
                                color: onSurface.withValues(
                                    alpha: 0.45))),
                      ],
                    ),
                  ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Text(
                        _mood == 1
                            ? 'Nothing in progress yet — play something and it will wait for you here.'
                            : 'No favorites yet — tap Save on any video to keep it here.',
                        style: TextStyle(
                            fontSize: 14,
                            color: onSurface.withValues(
                                alpha: 0.6)),
                      ),
                    ),
                  for (var i = 0; i < shown.length; i++)
                    _numberedRow(
                        context, ref, shown[i], i, videos),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, WidgetRef ref, int total, int favCount) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Text('folio.',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: onSurface)),
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              Text('№ ${total.toString().padLeft(2, '0')} — WARM',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: onSurface.withValues(alpha: 0.45))),
              IconButton(
                tooltip: 'Settings',
                onPressed: () =>
                    Navigator.of(context).pushNamed('/settings'),
                icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedSettings01,
                    color: onSurface),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 12),
              children: [
                _moodChip(context, 'All moods', 0),
                const SizedBox(width: 8),
                _moodChip(context, 'Continue', 1),
                const SizedBox(width: 8),
                _moodChip(context, 'Favorites', 2,
                    count: favCount),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _rule(onSurface),
          ),
        ],
      ),
    );
  }

  Widget _moodChip(BuildContext context, String label, int i,
      {int? count}) {
    final cs = Theme.of(context).colorScheme;
    final active = _mood == i;
    return GestureDetector(
      onTap: () => setState(() => _mood = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          count != null && count > 0 ? '$label · $count' : label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF16130E)
                      : Colors.white)
                  : cs.primary),
        ),
      ),
    );
  }

  Widget _rule(Color onSurface) => Container(
      height: 1, color: onSurface.withValues(alpha: 0.2));

  Widget _leadStory(BuildContext context, WidgetRef ref, VideoItem v,
      Map<String, Map<String, int>> history, List<VideoItem> all) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final pos = history[v.id]?['pos'] ?? 0;
    final frac = v.durationMs == 0
        ? 0.0
        : (pos / v.durationMs).clamp(0.0, 1.0);
    final meta =
        '${formatDuration(Duration(milliseconds: v.durationMs))} · ${formatBytes(v.sizeBytes)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: GestureDetector(
        onTap: () => _open(context, ref, v, all),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('LEAD STORY',
                      style: TextStyle(
                          color: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? const Color(0xFF16130E)
                              : Colors.white,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(meta.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w700,
                          color:
                              onSurface.withValues(alpha: 0.5))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(v.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.5,
                    color: onSurface)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoThumb(
                        video: v,
                        width: 400,
                        height: 200,
                        radius: 0),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: frac == 0 ? 0.02 : frac,
                              strokeWidth: 3,
                              color: cs.secondary,
                              backgroundColor: Colors.white
                                  .withValues(alpha: 0.3),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                  frac > 0
                                      ? Icons.play_arrow
                                      : Icons.play_arrow,
                                  color: const Color(0xFF23201A),
                                  size: 22),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withValues(alpha: 0.7),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: Text(
                          formatDuration(Duration(
                              milliseconds: v.durationMs)),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberedRow(BuildContext context, WidgetRef ref,
      VideoItem v, int i, List<VideoItem> all) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    return GestureDetector(
      onTap: () => _open(context, ref, v, all),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: onSurface.withValues(alpha: 0.14))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text((i + 1).toString().padLeft(2, '0'),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: i == 0
                          ? cs.primary
                          : onSurface.withValues(alpha: 0.4))),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: onSurface)),
                  Text(
                      '${formatDuration(Duration(milliseconds: v.durationMs))} — ${v.folder.isEmpty ? 'DEVICE' : v.folder}'
                          .toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color:
                              onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            VideoThumb(video: v, width: 72, height: 44, radius: 10),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, VideoItem v,
      List<VideoItem> all) {
    ref.read(playerProvider).open(v, contextQueue: all);
    Navigator.of(context).pushNamed('/player');
  }

  List<VideoItem> _continueWatching(List<VideoItem> videos,
      Map<String, Map<String, int>> history) {
    final out = <VideoItem>[];
    final sorted = history.entries.toList()
      ..sort((a, b) =>
          (b.value['ts'] ?? 0).compareTo(a.value['ts'] ?? 0));
    for (final e in sorted.take(8)) {
      final v =
          videos.where((x) => x.id == e.key).firstOrNull;
      if (v == null) continue;
      final pos = e.value['pos'] ?? 0;
      final dur = e.value['dur'] ?? v.durationMs;
      if (pos > 3000 && dur > 0 && pos < dur * 0.95) out.add(v);
    }
    return out;
  }

  Widget _firstRunState(BuildContext context, WidgetRef ref,
      (Object, String?) status) {
    final s = status.$1;
    if (s == LibraryStatus.permissionDenied) {
      return EmptyState(
        icon: HugeIcons.strokeRoundedLockKey,
        title: 'Videos aren\'t accessible',
        message:
            'Nova Play needs video access to show your library. You can enable it in Settings.',
        actionLabel: 'Open settings',
        onAction: () =>
            ref.read(libraryRepoProvider).openSettings(),
      );
    }
    if (s == LibraryStatus.permissionRequired) {
      return EmptyState(
        icon: HugeIcons.strokeRoundedVideo01,
        title: 'Allow access to videos',
        message:
            'Pick “Allow all” to scan every video, or “Select videos” to choose which ones Nova Play can play. Nothing is uploaded.',
        actionLabel: 'Allow access',
        onAction: () => ref
            .read(libraryProvider.notifier)
            .refresh(prompt: true),
      );
    }
    if (s == LibraryStatus.failure) {
      return EmptyState(
        icon: HugeIcons.strokeRoundedAlert02,
        title: 'Library scan failed',
        message: status.$2 ?? 'Try scanning again.',
        actionLabel: 'Retry',
        onAction: () =>
            ref.read(libraryProvider.notifier).refresh(),
      );
    }
    final notifier = ref.read(libraryProvider.notifier);
    if (notifier.lastLimited) {
      // Android 14+ "select videos" grant with nothing picked: the system
      // picker cannot be re-shown, so lead the user to the system panel.
      return EmptyState(
        icon: HugeIcons.strokeRoundedVideoOff,
        title: 'No videos selected',
        message:
            'Nova Play has limited access but no videos were selected. Open the system settings and choose videos under “Photos and videos”.',
        actionLabel: 'Open settings',
        onAction: () =>
            ref.read(libraryRepoProvider).openSettings(),
      );
    }
    return EmptyState(
      icon: HugeIcons.strokeRoundedVideoOff,
      title: 'No videos found',
      message:
          'We couldn\'t find videos on this device. Add some MP4 or MKV files, or if you selected only some videos earlier, allow more in the system permission sheet.',
      actionLabel: 'Rescan',
      onAction: () =>
          ref.read(libraryProvider.notifier).refresh(),
    );
  }
}

// (Search lives in the shell tab strip; the header only keeps Settings.)

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
