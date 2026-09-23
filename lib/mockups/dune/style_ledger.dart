import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../mockup_data.dart';
import 'dune_base.dart';

/// DIRECTION 6 — "Ledger" (Hearth × Mono).
/// Hearth's warmth (sand, greeting, mood chips, resume ring, carousels)
/// ruled by Mono's discipline (numbered index, tabular order).
class LedgerMock extends MockStyleBase {
  static const config = DuneConfig(
    bg: Color(0xFFF3EBDC),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF2E2A22),
    accent: Color(0xFF7A8B6F),
    accent2: Color(0xFFE9B84C),
    soft: Color(0xFFE9DCC2),
    blobA: Color(0xFFE7D9BE),
    blobB: Color(0xFFEBDCC0),
    radius: 20,
    tabStyle: 0,
    playerMode: 0,
    dark: false,
    wordmark: 'ledger',
    sub: 'hearth × mono',
  );

  @override
  String get name => 'Ledger';

  @override
  String get tagline => 'Hearth warmth · Mono index · ring + numbers';

  @override
  List<int> thumbnails() => [0, 5, 9];

  @override
  ThemeData theme() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: config.bg,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF7A8B6F),
          secondary: Color(0xFFE9B84C),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF2E2A22),
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
              color: config.ink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('Ld',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good evening, Hala',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E2A22))),
                Text('№ 06 — 10 ENTRIES, 3 OPEN',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                        color: Color(0x802E2A22))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
                icon: HugeIcons.strokeRoundedSettings01,
                color: Color(0xFF2E2A22),
                size: 18),
          ),
        ],
      ),
    );
  }

  Widget _explore(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              DuneChip(label: 'All moods', active: true, onTap: () {}),
              const SizedBox(width: 8),
              DuneChip(label: 'Relaxed', active: false, onTap: () {}),
              const SizedBox(width: 8),
              DuneChip(label: 'Travel', active: false, onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _hero(context),
        const SizedBox(height: 22),
        const DuneSectionTitle('Open entries', note: '01 — 03 resume'),
        const SizedBox(height: 4),
        for (var i = 0; i < 3; i++) _numberedRow(context, [0, 4, 7][i]),
        const SizedBox(height: 22),
        const DuneSectionTitle('Fresh finds'),
        const SizedBox(height: 10),
        _carousel(context, [1, 2, 3, 6, 8, 9]),
        const SizedBox(height: 22),
        const DuneSectionTitle('Full ledger', note: '01 — 10'),
        const SizedBox(height: 4),
        for (var i = 0; i < mockVideos.length; i++)
          _numberedRow(context, i),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    final v = mockVideos[0];
    return GestureDetector(
      onTap: () => openDunePlayer(context, config, 0),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: config.ink.withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
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
                left: 18,
                bottom: 16,
                right: 84,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ENTRY 01',
                        style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w800,
                            color: config.accent2)),
                    const SizedBox(height: 4),
                    Text(v.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 0.62,
                        strokeWidth: 3,
                        color: config.accent2,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.3),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedPlay,
                            color: Color(0xFF2E2A22),
                            size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
                  color: config.ink.withValues(alpha: 0.12))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text('${(i + 1).toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: i < 3
                          ? config.accent
                          : config.ink.withValues(alpha: 0.35))),
            ),
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
                          color: Color(0xFF2E2A22))),
                  Text('${v.meta} · ${v.duration}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0x802E2A22))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 76,
              child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: MockArtwork(video: v, radius: 10)),
            ),
          ],
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
              width: 152,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MockArtwork(video: v, radius: 18),
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
                          color: Color(0xFF2E2A22))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _saved(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kept entries',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E2A22))),
          Text('04 MARKED PASSAGES',
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
                              color: config.accent, width: 4)),
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
                                          Color(0xFF2E2A22))),
                              Text(
                                  '${v.meta} · ${v.duration}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color:
                                          Color(0x802E2A22))),
                            ],
                          ),
                        ),
                        const HugeIcon(
                            icon: HugeIcons
                                .strokeRoundedFavourite,
                            color: Color(0xFFFF6B5E),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: [
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: config.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: config.ink.withValues(alpha: 0.4),
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Search entries or moods…',
                    style: TextStyle(
                        fontSize: 14,
                        color:
                            config.ink.withValues(alpha: 0.45))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const DuneSectionTitle('Moods'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in [
              'road trip',
              'slow tv',
              'city rain',
              '4k walks'
            ])
              DuneChip(label: q, active: false, onTap: () {}),
          ],
        ),
        const SizedBox(height: 20),
        const DuneSectionTitle('Recent', note: null),
        const SizedBox(height: 4),
        for (var i = 0; i < 3; i++) _numberedRow(context, i + 4),
      ],
    );
  }
}
