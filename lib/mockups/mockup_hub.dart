import 'package:flutter/material.dart';
import 'mockup_data.dart';
import 'dune/style_hearth.dart';
import 'dune/style_atrium.dart';
import 'dune/style_nebula_v2.dart';
import 'dune/style_mono_v2.dart';
import 'dune/style_estuary.dart';
import 'dune/style_ledger.dart';
import 'dune/style_folio.dart';
import 'dune/player_lab.dart';

/// MOCKUP GALLERY — v2 (all 7 born from Dune).
/// Run with:
///   flutter run -t lib/mockups/main_mockups_v2.dart
class MockupHubV2 extends StatelessWidget {
  const MockupHubV2({super.key});
  static final styles = <MockStyleBase>[
    HearthMock(),
    AtriumMock(),
    NebulaV2Mock(),
    MonoV2Mock(),
    EstuaryMock(),
    LedgerMock(),
    FolioMock(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova Play — 7 Dune directions',
      debugShowCheckedModeBanner: false,
      theme: _hubTheme(),
      home: const _HubGrid(),
    );
  }

  ThemeData _hubTheme() {
    const bg = Color(0xFF17150F);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD89F48),
        surface: Color(0xFF211D15),
        onSurface: Colors.white,
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final MockStyleBase style;
  final int n;
  final VoidCallback onTap;
  const _StyleCard(
      {required this.style, required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF211D15),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _dot(),
                  const SizedBox(width: 8),
                  Text(
                    'DIRECTION ${n + 1}',
                    style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB4A27C)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(style.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Text(style.tagline,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13)),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final m in style.thumbnails())
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(right: 8),
                        child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: MockArtwork(
                                video: mockVideos[m],
                                radius: 8)),
                      ),
                    ),
                ],
              ),
              if (style.navPreview != null)
                Expanded(
                  child: Center(
                    child: style.navPreview!(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot() => Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFD89F48),
        ),
      );
}

class _ConceptCard extends StatelessWidget {
  final PlayerConcept concept;
  const _ConceptCard({required this.concept});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF211D15),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => Theme(
                    data: concept.theme(),
                    child:
                        Scaffold(body: concept.screen()),
                  )));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFD89F48)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.play_arrow,
                  color: Color(0xFFD89F48), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(concept.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text(concept.tagline,
                        style: TextStyle(
                            color: Colors.white
                                .withValues(alpha: 0.55),
                            fontSize: 13)),
                  ]),
            ),
            const Icon(Icons.arrow_forward,
                color: Color(0xFFB4A27C), size: 20),
          ]),
        ),
      ),
    );
  }
}

class _HubGrid extends StatelessWidget {
  const _HubGrid();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seven directions, one dune'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0;
              i < MockupHubV2.styles.length;
              i++) ...[
            _StyleCard(
              style: MockupHubV2.styles[i],
              n: i,
              onTap: () {
                final s = MockupHubV2.styles[i];
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => Theme(
                          data: s.theme(),
                          child: Scaffold(body: s.screen()),
                        )));
              },
            ),
            const SizedBox(height: 14),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 10, 4, 12),
            child: Text('PLAYER CONCEPTS — the playing page',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB4A27C))),
          ),
          for (final p in playerConcepts) ...[
            _ConceptCard(concept: p),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
