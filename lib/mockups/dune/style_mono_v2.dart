import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../mockup_data.dart';
import 'dune_base.dart';

/// DIRECTION 4 — "Mono" (warm editorial).
/// Sand paper, ink text, ONE burnt-red accent, numbered lists,
/// side-rail nav, compact dock player. Quiet and confident.
class MonoV2Mock extends MockStyleBase {
  static const config = DuneConfig(
    bg: Color(0xFFF1EAD9),
    surface: Color(0xFFFBF7EC),
    ink: Color(0xFF23201A),
    accent: Color(0xFFB33A2B),
    accent2: Color(0xFF23201A),
    soft: Color(0xFFE3D7BE),
    blobA: Color(0xFFE8DCC2),
    blobB: Color(0xFFE8DCC2),
    radius: 14,
    tabStyle: 2,
    playerMode: 2,
    dark: false,
    wordmark: 'mono',
    sub: 'no. 04',
  );

  @override
  String get name => 'Mono';

  @override
  String get tagline => 'Warm editorial · one red · side rail';

  @override
  List<int> thumbnails() => [5, 1, 9];

  @override
  ThemeData theme() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: config.bg,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFB33A2B),
          secondary: Color(0xFF23201A),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('mono.',
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
                  color: Color(0xFFB33A2B),
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              Text('№ 04 — SAND',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: config.ink.withValues(alpha: 0.45))),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: config.ink.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _explore(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _leadStory(context),
        const SizedBox(height: 20),
        _rule(),
        const SizedBox(height: 12),
        const DuneSectionTitle('Index', note: '01 — 10'),
        const SizedBox(height: 4),
        for (var i = 0; i < mockVideos.length; i++)
          _numberedRow(context, i),
      ],
    );
  }

  Widget _rule() =>
      Container(height: 1, color: config.ink.withValues(alpha: 0.2));

  /// Big editorial lead story instead of a glossy hero.
  Widget _leadStory(BuildContext context) {
    final v = mockVideos[5];
    return GestureDetector(
      onTap: () => openDunePlayer(context, config, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                color: config.accent,
                child: const Text('LEAD',
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
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  letterSpacing: -0.5,
                  color: Color(0xFF23201A))),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MockArtwork(video: v, radius: 10),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: MockDurationBadge(v.duration),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                color: config.ink,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                        icon: HugeIcons.strokeRoundedPlay,
                        color: Colors.white,
                        size: 14),
                    SizedBox(width: 8),
                    Text('READ / WATCH',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('62% watched',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: config.accent)),
            ],
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: config.ink.withValues(alpha: 0.14))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Text('${(i + 1).toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: i == 0
                          ? config.accent
                          : config.ink.withValues(alpha: 0.4))),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF23201A))),
                  Text(
                      '${v.meta} — ${v.duration}'
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
            SizedBox(
              width: 72,
              child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: MockArtwork(video: v, radius: 6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saved(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                      border: Border(
                          left: BorderSide(
                              color: config.accent,
                              width: 3)),
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
                        HugeIcon(
                            icon: HugeIcons
                                .strokeRoundedFavourite,
                            color: config.accent,
                            size: 18),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
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
              'ROADS',
              'NIGHT'
            ])
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: config.ink.withValues(alpha: 0.35)),
                ),
                child: Text(q,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Color(0xFF23201A))),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _rule(),
        const SizedBox(height: 8),
        for (var i = 0; i < 3; i++) _numberedRow(context, i + 4),
      ],
    );
  }
}
