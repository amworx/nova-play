import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../mockup_data.dart';
import 'dune_base.dart';

/// DIRECTION 2 — "Atrium" (terracotta garden).
/// Clay + deep moss, arch-topped hero, top-chip tabs,
/// masonry saved wall, fullbleed cinema player.
class AtriumMock extends MockStyleBase {
  static const config = DuneConfig(
    bg: Color(0xFFF6EFE3),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF3A2E24),
    accent: Color(0xFFB4552D),
    accent2: Color(0xFF5F7150),
    soft: Color(0xFFEAD9C2),
    blobA: Color(0xFFF0D9BE),
    blobB: Color(0xFFDFE4CF),
    radius: 20,
    tabStyle: 1,
    playerMode: 1,
    dark: false,
    wordmark: 'atrium',
    sub: 'garden cinema',
  );

  @override
  String get name => 'Atrium';

  @override
  String get tagline => 'Terracotta garden · arch hero · top chips';

  @override
  List<int> thumbnails() => [6, 2, 4];

  @override
  ThemeData theme() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: config.bg,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFB4552D),
          secondary: Color(0xFF5F7150),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF3A2E24),
        ),
      );

  @override
  Widget screen() => DuneScope(
        config: config,
        child: DuneHome(
          cfg: config,
          header: _header,
          explore: _explore,
          saved: _saved,
          search: _search,
        ),
      );

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: config.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('atrium',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(width: 8),
              Text(config.sub,
                  style: TextStyle(
                      fontSize: 13,
                      color: config.ink.withValues(alpha: 0.5))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCompass,
                    color: Color(0xFF3A2E24),
                    size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Planted for slow evenings',
              style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3A2E24))),
        ],
      ),
    );
  }

  Widget _explore(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _archHero(context),
        const SizedBox(height: 22),
        const DuneSectionTitle('Water daily',
            note: 'your continuing beds'),
        const SizedBox(height: 10),
        _carousel(context, [6, 4, 0]),
        const SizedBox(height: 22),
        const DuneSectionTitle('Sun beds', note: 'bright and short'),
        const SizedBox(height: 10),
        _carousel(context, [1, 3, 8, 9]),
        const SizedBox(height: 22),
        const DuneSectionTitle('Whole greenhouse'),
        const SizedBox(height: 6),
        for (var i = 0; i < mockVideos.length; i++)
          _row(context, i),
      ],
    );
  }

  /// Hero with an arched top — the garden doorway.
  Widget _archHero(BuildContext context) {
    final v = mockVideos[6];
    return GestureDetector(
      onTap: () => openDunePlayer(context, config, 6),
      child: Container(
        height: 228,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(110),
            topRight: Radius.circular(110),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
                color: config.accent.withValues(alpha: 0.22),
                blurRadius: 26,
                offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(110),
            topRight: Radius.circular(110),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MockArtwork(video: v, radius: 0, glyph: false),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 22,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('FEATURED BED',
                        style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800,
                            color: config.accent)),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(v.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800)),
                          Text('${v.meta} · ${v.duration}',
                              style: TextStyle(
                                  color: Colors.white
                                      .withValues(alpha: 0.75),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: config.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedPlay,
                          color: Colors.white,
                          size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carousel(BuildContext context, List<int> indices) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: indices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final idx = indices[i];
          final v = mockVideos[idx];
          return GestureDetector(
            onTap: () => openDunePlayer(context, config, idx),
            child: SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MockArtwork(video: v, radius: 18),
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const HugeIcon(
                                icon: HugeIcons
                                    .strokeRoundedFavourite,
                                color: Colors.white,
                                size: 12),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child:
                              MockDurationBadge(v.duration),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(v.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A2E24))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, int i) {
    final v = mockVideos[i];
    return GestureDetector(
      onTap: () => openDunePlayer(context, config, i),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: config.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: config.soft.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: MockArtwork(video: v, radius: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A2E24))),
                  Text('${v.meta} · ${v.duration}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0x803A2E24))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: config.soft.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlay,
                  color: config.accent,
                  size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saved(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cuttings',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3A2E24))),
          const Text('saved to replant later',
              style:
                  TextStyle(fontSize: 13, color: Color(0x803A2E24))),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: 6,
              itemBuilder: (_, i) {
                final v = mockVideos[i % mockVideos.length];
                return GestureDetector(
                  onTap: () =>
                      openDunePlayer(context, config, i),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: config.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: config.soft
                              .withValues(alpha: 0.7)),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: MockArtwork(
                                video: v, radius: 14)),
                        const SizedBox(height: 8),
                        Text(v.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF3A2E24))),
                        Text(v.duration,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0x803A2E24))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _search(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: config.surface,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
                color: config.soft.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: config.accent,
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Search the beds…',
                    style: TextStyle(
                        fontSize: 14,
                        color:
                            config.ink.withValues(alpha: 0.45))),
              ),
              HugeIcon(
                  icon: HugeIcons.strokeRoundedFilter,
                  color: config.ink.withValues(alpha: 0.4),
                  size: 18),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Wander by bed',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3A2E24))),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: 6,
          itemBuilder: (_, i) {
            final labels = [
              'Desert',
              'Forest',
              'City',
              'Ocean',
              'Kitchen',
              'Roads'
            ];
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i.isEven
                    ? config.accent.withValues(alpha: 0.12)
                    : config.accent2.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: i.isEven
                          ? config.accent
                          : config.accent2)),
            );
          },
        ),
        const SizedBox(height: 20),
        const DuneSectionTitle('Recently wandered'),
        const SizedBox(height: 6),
        for (var i = 0; i < 3; i++) _row(context, i + 2),
      ],
    );
  }
}
