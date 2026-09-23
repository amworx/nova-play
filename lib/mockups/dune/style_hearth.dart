import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../mockup_data.dart';
import 'dune_base.dart';

/// DIRECTION 1 — "Hearth" (Dune enhanced).
/// The refined Dune: warmer sand, greeting header, mood chips,
/// hero with resume ring, three-tier browsing, inset player.
class HearthMock extends MockStyleBase {
  static const config = DuneConfig(
    bg: Color(0xFFF3EBDC),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF2E2A22),
    accent: Color(0xFF7A8B6F),
    accent2: Color(0xFFE9B84C),
    soft: Color(0xFFE9DCC2),
    blobA: Color(0xFFE7D9BE),
    blobB: Color(0xFFEBDCC0),
    radius: 24,
    tabStyle: 0,
    playerMode: 0,
    dark: false,
    wordmark: 'hearth',
    sub: 'warm cinema',
  );

  @override
  String get name => 'Hearth';

  @override
  String get tagline => 'Dune enhanced · resume ring · mood chips';

  @override
  List<int> thumbnails() => [0, 4, 7];

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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7A8B6F), Color(0xFF5C6E54)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('hy',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
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
                Text('3 videos waiting for you',
                    style: TextStyle(
                        fontSize: 12,
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
              const SizedBox(width: 8),
              DuneChip(label: 'Slow TV', active: false, onTap: () {}),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _hero(context),
        const SizedBox(height: 24),
        const DuneSectionTitle('Continue',
            note: 'picked up where you left off'),
        const SizedBox(height: 10),
        _carousel(context, [0, 4, 7], resume: true),
        const SizedBox(height: 24),
        const DuneSectionTitle('Fresh finds'),
        const SizedBox(height: 10),
        _carousel(context, [1, 2, 3, 6, 8, 9]),
        const SizedBox(height: 24),
        const DuneSectionTitle('Everything'),
        const SizedBox(height: 6),
        for (var i = 0; i < mockVideos.length; i++)
          _row(context, i),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    final v = mockVideos[0];
    return GestureDetector(
      onTap: () => openDunePlayer(context, config, 0),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: config.ink.withValues(alpha: 0.10),
                blurRadius: 26,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: config.accent2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('BRING BACK THE MAGIC',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w800,
                              color: config.ink)),
                    ),
                    const SizedBox(height: 8),
                    Text(v.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('${v.meta} · ${v.duration}',
                        style: TextStyle(
                            color: Colors.white
                                .withValues(alpha: 0.7))),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: _resumeRing(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumeRing() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 0.62,
            strokeWidth: 3,
            color: config.accent2,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
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
    );
  }

  Widget _carousel(BuildContext context, List<int> indices,
      {bool resume = false}) {
    return SizedBox(
      height: 178,
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
              width: 158,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MockArtwork(video: v, radius: 20),
                        if (resume)
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black
                                    .withValues(alpha: 0.7),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: const Text('62%',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w800)),
                            ),
                          )
                        else
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

  Widget _row(BuildContext context, int i) {
    final v = mockVideos[i];
    return GestureDetector(
      onTap: () => openDunePlayer(context, config, i),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: MockArtwork(video: v, radius: 16)),
            ),
            const SizedBox(width: 14),
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
            HugeIcon(
                icon: HugeIcons.strokeRoundedFavourite,
                color: i % 3 == 0
                    ? const Color(0xFFFF6B5E)
                    : config.soft,
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
          const Text('Saved',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E2A22))),
          const Text('Marked with a heart',
              style:
                  TextStyle(fontSize: 13, color: Color(0x802E2A22))),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemCount: 4,
              itemBuilder: (_, i) => Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () =>
                          openDunePlayer(context, config, i),
                      child:
                          MockArtwork(video: mockVideos[i], radius: 22),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          color: Color(0xFFFF6B5E),
                          size: 16),
                    ),
                  ),
                ],
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
            boxShadow: [
              BoxShadow(
                  color: config.ink.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: config.ink.withValues(alpha: 0.4),
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Search by title or folder…',
                    style: TextStyle(
                        fontSize: 14,
                        color:
                            config.ink.withValues(alpha: 0.45))),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: config.accent,
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedMic01,
                    color: Colors.white,
                    size: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Moods we made for you',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E2A22))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in [
              'road trip',
              'sushi night',
              'northern lights',
              'city rain'
            ])
              DuneChip(label: q, active: false, onTap: () {}),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Popular now',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0x992E2A22))),
        const SizedBox(height: 10),
        for (var i = 0; i < 3; i++) _row(context, i),
      ],
    );
  }
}
