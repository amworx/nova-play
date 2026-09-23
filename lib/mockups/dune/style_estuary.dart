import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../mockup_data.dart';
import 'dune_base.dart';

/// DIRECTION 5 — "Estuary" (coastal drift).
/// Seafoam + driftwood + coral, wave blobs, film-strip reels,
/// tide-line saved shelf, bottom pill nav, inset player.
class EstuaryMock extends MockStyleBase {
  static const config = DuneConfig(
    bg: Color(0xFFEFF3EA),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF26332E),
    accent: Color(0xFF3E7C6B),
    accent2: Color(0xFFE2725B),
    soft: Color(0xFFDCE7DC),
    blobA: Color(0xFFCFE3D8),
    blobB: Color(0xFFF2DFC8),
    radius: 26,
    tabStyle: 0,
    playerMode: 0,
    dark: false,
    wordmark: 'estuary',
    sub: 'tide cinema',
  );

  @override
  String get name => 'Estuary';

  @override
  String get tagline => 'Coastal drift · reels · tide shelf';

  @override
  List<int> thumbnails() => [7, 4, 1];

  @override
  ThemeData theme() => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: config.bg,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3E7C6B),
          secondary: Color(0xFFE2725B),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF26332E),
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
                colors: [Color(0xFF3E7C6B), Color(0xFF2C5A4E)],
              ),
              borderRadius: BorderRadius.circular(23),
            ),
            child: const HugeIcon(
                icon: HugeIcons.strokeRoundedPlay,
                color: Colors.white,
                size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('High tide, Hala',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF26332E))),
                Text('the reels drifted in overnight',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0x8026332E))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: config.accent2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('2 new',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _explore(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        _tideHero(context),
        const SizedBox(height: 22),
        const DuneSectionTitle('Drift back in',
            note: 'continue the current'),
        const SizedBox(height: 10),
        _reelStrip(context, [7, 4, 1]),
        const SizedBox(height: 22),
        const DuneSectionTitle('Fresh catch'),
        const SizedBox(height: 10),
        _reelStrip(context, [0, 2, 3, 6, 8, 9]),
        const SizedBox(height: 22),
        const DuneSectionTitle('Shoreline', note: 'everything a–z'),
        const SizedBox(height: 6),
        for (var i = 0; i < mockVideos.length; i++)
          _row(context, i),
      ],
    );
  }

  /// Wide hero with a wave divider at the bottom.
  Widget _tideHero(BuildContext context) {
    final v = mockVideos[7];
    return GestureDetector(
      onTap: () => openDunePlayer(context, config, 7),
      child: Container(
        height: 214,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: config.accent.withValues(alpha: 0.22),
                blurRadius: 26,
                offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
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
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
              // wave lip
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(48),
                      topRight: Radius.circular(70),
                    ),
                  ),
                ),
              ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: config.accent2,
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Text('TIDE PICK',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(height: 6),
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
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: HugeIcon(
                          icon: HugeIcons.strokeRoundedPlay,
                          color: config.accent,
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

  /// Film-strip: perforated edges top + bottom, sprocket holes.
  Widget _reelStrip(BuildContext context, List<int> indices) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF26332E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _sprockets(),
          const SizedBox(height: 10),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14),
              itemCount: indices.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final idx = indices[i];
                final v = mockVideos[idx];
                return GestureDetector(
                  onTap: () =>
                      openDunePlayer(context, config, idx),
                  child: SizedBox(
                    width: 168,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MockArtwork(video: v, radius: 12),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Text(v.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child:
                              MockDurationBadge(v.duration),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _sprockets(),
        ],
      ),
    );
  }

  Widget _sprockets() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < 14; i++)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
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
                  child: MockArtwork(video: v, radius: 18)),
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
                          color: Color(0xFF26332E))),
                  Text('${v.meta} · ${v.duration}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0x8026332E))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: config.soft.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                  icon: HugeIcons.strokeRoundedGoForward10Sec,
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tide shelf',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF26332E))),
          const Text('what the sea kept for you',
              style:
                  TextStyle(fontSize: 13, color: Color(0x8026332E))),
          const SizedBox(height: 16),
          // shelf: artwork on a wooden plank line
          Expanded(
            child: ListView.separated(
              itemCount: 4,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 18),
              itemBuilder: (_, i) {
                final v = mockVideos[i];
                return GestureDetector(
                  onTap: () =>
                      openDunePlayer(context, config, i),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 8,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MockArtwork(
                                video: v, radius: 20),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Container(
                                padding:
                                    const EdgeInsets.all(7),
                                decoration:
                                    const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: HugeIcon(
                                    icon: HugeIcons
                                        .strokeRoundedFavourite,
                                    color: config.accent2,
                                    size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 8,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9B18C),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                      ),
                    ],
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
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: config.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: config.accent,
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Search shells and reels…',
                    style: TextStyle(
                        fontSize: 14,
                        color:
                            config.ink.withValues(alpha: 0.45))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Drift lines',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF26332E))),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final q in [
                'underwater',
                'harbours',
                'storms',
                'slow mornings',
                'coral'
              ]) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: config.accent
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(q,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: config.accent)),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const DuneSectionTitle('Washed up today'),
        const SizedBox(height: 6),
        for (var i = 0; i < 3; i++) _row(context, i + 5),
      ],
    );
  }
}
