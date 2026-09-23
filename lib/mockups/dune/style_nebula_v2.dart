import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../mockup_data.dart';
import 'dune_base.dart';

/// DIRECTION 3 — "Nocturne" (desert night).
/// Deep espresso sky, amber starlight, glowing hero,
/// bottom pill nav, fullbleed night player.
class NebulaV2Mock extends MockStyleBase {
  static const config = DuneConfig(
    bg: Color(0xFF17130D),
    surface: Color(0xFF241E14),
    ink: Color(0xFFF5EDE0),
    accent: Color(0xFFD89F48),
    accent2: Color(0xFF8FA876),
    soft: Color(0xFF3A3226),
    blobA: Color(0xFF4A3418),
    blobB: Color(0xFF2C3A28),
    radius: 24,
    tabStyle: 0,
    playerMode: 1,
    dark: true,
    wordmark: 'nocturne',
    sub: 'after dark',
  );

  @override
  String get name => 'Nocturne';

  @override
  String get tagline => 'Desert night · amber glow · fullbleed';

  @override
  List<int> thumbnails() => [3, 7, 5];

  @override
  ThemeData theme() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: config.bg,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD89F48),
          secondary: Color(0xFF8FA876),
          surface: Color(0xFF241E14),
          onSurface: Color(0xFFF5EDE0),
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: config.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: config.accent.withValues(alpha: 0.4)),
            ),
            child: HugeIcon(
                icon: HugeIcons.strokeRoundedClock01,
                color: config.accent,
                size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tonight’s sky',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF5EDE0))),
                Text('10 titles · 2 continuing',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0x99F5EDE0))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: config.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('1.5x',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF17130D))),
          ),
        ],
      ),
    );
  }

  Widget _explore(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        _glowHero(context),
        const SizedBox(height: 22),
        const DuneSectionTitle('Still burning',
            note: 'resume under starlight'),
        const SizedBox(height: 10),
        _carousel(context, [3, 7, 5]),
        const SizedBox(height: 22),
        const DuneSectionTitle('New constellations'),
        const SizedBox(height: 10),
        _carousel(context, [0, 1, 2, 8, 9]),
        const SizedBox(height: 22),
        const DuneSectionTitle('Whole sky'),
        const SizedBox(height: 6),
        for (var i = 0; i < mockVideos.length; i++)
          _row(context, i),
      ],
    );
  }

  Widget _glowHero(BuildContext context) {
    final v = mockVideos[3];
    return GestureDetector(
      onTap: () => openDunePlayer(context, config, 3),
      child: Container(
        height: 216,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: config.accent.withValues(alpha: 0.30),
                blurRadius: 34,
                offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
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
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              // star dots
              ...[
                const Offset(40, 30),
                const Offset(120, 52),
                const Offset(220, 28),
                const Offset(280, 60),
                const Offset(180, 36),
              ].map((o) => Positioned(
                    left: o.dx,
                    top: o.dy,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )),
              Positioned(
                left: 18,
                bottom: 16,
                right: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(v.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900)),
                          Text('${v.meta} · ${v.duration}',
                              style: TextStyle(
                                  color: Colors.white
                                      .withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: config.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: config.accent
                                  .withValues(alpha: 0.55),
                              blurRadius: 20,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedPlay,
                          color: Color(0xFF17130D),
                          size: 22),
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
      height: 172,
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
              width: 154,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: config.accent
                                .withValues(alpha: 0.25)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MockArtwork(video: v, radius: 0, glyph: false),
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: MockDurationBadge(
                                  v.duration),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(v.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF5EDE0))),
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
        ),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              child: AspectRatio(
                  aspectRatio: 16 / 9,
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
                          color: Color(0xFFF5EDE0))),
                  Text('${v.meta} · ${v.duration}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0x99F5EDE0))),
                ],
              ),
            ),
            HugeIcon(
                icon: HugeIcons.strokeRoundedPlay,
                color: config.accent,
                size: 20),
          ],
        ),
      ),
    );
  }

  Widget _saved(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pinned stars',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF5EDE0))),
          const Text('saved for late nights',
              style:
                  TextStyle(fontSize: 13, color: Color(0x99F5EDE0))),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.0,
              ),
              itemCount: 4,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () =>
                    openDunePlayer(context, config, i),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: config.accent
                            .withValues(alpha: 0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: MockArtwork(
                        video: mockVideos[i], radius: 0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _search(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: [
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: config.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color:
                    config.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: config.accent,
                  size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Search the night sky…',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0x99F5EDE0))),
              ),
              HugeIcon(
                  icon: HugeIcons.strokeRoundedMic01,
                  color: config.ink.withValues(alpha: 0.5),
                  size: 18),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text('Night drives',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF5EDE0))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in [
              'neon',
              'slow tv',
              'ocean',
              'city rain',
              '4k walks'
            ])
              DuneChip(label: q, active: false, onTap: () {}),
          ],
        ),
        const SizedBox(height: 22),
        const DuneSectionTitle('Brightest tonight'),
        const SizedBox(height: 6),
        for (var i = 0; i < 3; i++) _row(context, i + 3),
      ],
    );
  }
}
