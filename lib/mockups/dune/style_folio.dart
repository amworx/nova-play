import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../mockup_data.dart';
import 'dune_base.dart';

/// DIRECTION 7 — "Folio" (Mono × Hearth).
/// Mono's bones (side rail, lead story, rules, subjects)
/// warmed with Hearth's soul (sage + amber, mood chips,
/// resume ring, rounded cards, dock player).
class FolioMock extends MockStyleBase {
  static const config = DuneConfig(
    bg: Color(0xFFF1EAD9),
    surface: Color(0xFFFBF7EC),
    ink: Color(0xFF23201A),
    accent: Color(0xFF7A8B6F),
    accent2: Color(0xFFE9B84C),
    soft: Color(0xFFE3D7BE),
    blobA: Color(0xFFE8DCC2),
    blobB: Color(0xFFF0D9BE),
    radius: 18,
    tabStyle: 2,
    playerMode: 2,
    dark: false,
    wordmark: 'folio',
    sub: 'mono × hearth',
  );

  @override
  String get name => 'Folio';

  @override
  String get tagline => 'Mono bones · Hearth soul · rail + ring';

  @override
  List<int> thumbnails() => [4, 0, 7];

  @override
  ThemeData theme() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: config.bg,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF7A8B6F),
          secondary: Color(0xFFE9B84C),
          surface: Color(0xFFFBF7EC),
          onSurface: Color(0xFF23201A),
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
      padding: const EdgeInsets.fromLTRB(12, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('folio.',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Color(0xFF23201A))),
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF7A8B6F),
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              Text('№ 07 — WARM',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: config.ink.withValues(alpha: 0.45))),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                DuneChip(
                    label: 'All moods',
                    active: true,
                    onTap: () {}),
                const SizedBox(width: 8),
                DuneChip(
                    label: 'Slow TV',
                    active: false,
                    onTap: () {}),
                const SizedBox(width: 8),
                DuneChip(
                    label: 'Travel', active: false, onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
              height: 1,
              color: config.ink.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _explore(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 20, 24),
      children: [
        _leadStory(context),
        const SizedBox(height: 18),
        Container(
            height: 1,
            color: config.ink.withValues(alpha: 0.2)),
        const SizedBox(height: 12),
        const DuneSectionTitle('Index', note: '01 — 10'),
        const SizedBox(height: 4),
        for (var i = 0; i < mockVideos.length; i++)
          _numberedRow(context, i),
      ],
    );
  }

  Widget _leadStory(BuildContext context) {
    final v = mockVideos[4];
    return GestureDetector(
      onTap: () => openDunePlayer(context, config, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: config.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('LEAD STORY',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Text(v.meta.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                      color: config.ink.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(height: 10),
          Text(v.title,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.5,
                  color: Color(0xFF23201A))),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MockArtwork(
                      video: v, radius: 0, glyph: false),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black
                              .withValues(alpha: 0.35),
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
                            value: 0.62,
                            strokeWidth: 3,
                            color: config.accent2,
                            backgroundColor: Colors.white
                                .withValues(alpha: 0.3),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration:
                                const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: HugeIcon(
                                icon: HugeIcons
                                    .strokeRoundedPlay,
                                color: config.ink,
                                size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child:
                        MockDurationBadge(v.duration),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberedRow(BuildContext context, int i) {
    final v = mockVideos[i];
    return GestureDetector(
      onTap: () => openDunePlayer(context, config, i),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: config.ink.withValues(alpha: 0.14))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text('${(i + 1).toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: i == 4
                          ? config.accent
                          : config.ink.withValues(alpha: 0.4))),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF23201A))),
                  Text('${v.meta} — ${v.duration}'
                      .toUpperCase(),
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: config.ink
                              .withValues(alpha: 0.5))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: MockArtwork(video: v, radius: 0)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saved(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Marginalia',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF23201A))),
          Text('4 KEPT PASSAGES',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                  color: config.ink.withValues(alpha: 0.45))),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: 4,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final v = mockVideos[i];
                return GestureDetector(
                  onTap: () =>
                      openDunePlayer(context, config, i),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: config.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                          left: BorderSide(
                              color: config.accent,
                              width: 4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(v.title,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w800,
                                      color:
                                          Color(0xFF23201A))),
                              Text(v.duration,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: config.ink
                                          .withValues(
                                              alpha: 0.5))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: config.accent
                                .withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: HugeIcon(
                              icon: HugeIcons
                                  .strokeRoundedFavourite,
                              color: config.accent,
                              size: 16),
                        ),
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
      padding: const EdgeInsets.fromLTRB(12, 14, 20, 24),
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: config.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: config.ink),
          ),
          child: Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: config.ink,
                  size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text('SEARCH THE ARCHIVE…',
                    style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color:
                            config.ink.withValues(alpha: 0.45))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('SUBJECTS',
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
                color: config.ink.withValues(alpha: 0.45))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in [
              'DESERT',
              'CITY',
              'OCEAN',
              'FOOD',
              'ROADS'
            ])
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: config.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(q,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: config.accent)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
            height: 1,
            color: config.ink.withValues(alpha: 0.2)),
        const SizedBox(height: 8),
        for (var i = 0; i < 3; i++) _numberedRow(context, i + 2),
      ],
    );
  }
}
