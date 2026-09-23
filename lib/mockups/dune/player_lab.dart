import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../mockup_data.dart';
import 'dune_base.dart';
import 'style_folio.dart';

/// PLAYER LAB — 4 unique playing-page concepts on Folio's palette.
/// Opened from the hub's "Player concepts" section. Each is a full
/// mock player: autoplay session, seek, speeds, ONE share, details.
class PlayerConcept extends MockStyleBase {
  final String _name;
  final String _tagline;
  final Widget Function(DuneConfig) buildPlayer;
  PlayerConcept(this._name, this._tagline, this.buildPlayer);

  @override
  String get name => _name;
  @override
  String get tagline => _tagline;
  @override
  List<int> thumbnails() => [0];
  @override
  ThemeData theme() => FolioMock().theme();
  @override
  Widget screen() => DuneScope(
        config: FolioMock.config,
        child: buildPlayer(FolioMock.config),
      );
}

List<PlayerConcept> playerConcepts = [
  PlayerConcept('Orbit', 'progress ring you can drag',
      (c) => _OrbitPlayer(cfg: c, index: 0)),
  PlayerConcept('Chapters', 'the video as a document',
      (c) => _ChaptersPlayer(cfg: c, index: 0)),
  PlayerConcept('Tideform', 'waveform scrubbing',
      (c) => _TideformPlayer(cfg: c, index: 0)),
  PlayerConcept('Dial', 'a jog dial for your thumb',
      (c) => _DialPlayer(cfg: c, index: 0)),
];

/// Convert a drag position inside a square box to 0..1, 0 = top.
double _angleFraction(Offset local, Size size) {
  final cx = size.width / 2, cy = size.height / 2;
  final a = math.atan2(local.dy - cy, local.dx - cx);
  var f = (a + math.pi / 2) / (2 * math.pi);
  f = f % 1.0;
  return f;
}

/// Compact shared sheets for the lab (one share everywhere).
void _labShare(BuildContext ctx, DuneConfig cfg, String title) {
  showModalBottomSheet(
    context: ctx,
    backgroundColor: cfg.surface,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: cfg.ink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Share “$title”',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cfg.ink))),
          const SizedBox(height: 14),
          Row(children: [
            for (final o in [
              (Icons.ios_share, 'Share file'),
              (Icons.content_copy, 'Copy title'),
              (Icons.link, 'Copy path'),
            ])
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Mock — not wired'),
                            duration:
                                Duration(seconds: 1)));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color:
                            cfg.soft.withValues(alpha: 0.45),
                        borderRadius:
                            BorderRadius.circular(18)),
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding:
                                  const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                  color: cfg.accent,
                                  shape: BoxShape.circle),
                              child: Icon(o.$1,
                                  color: Colors.white,
                                  size: 18)),
                          const SizedBox(height: 10),
                          Text(o.$2,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: cfg.ink)),
                        ]),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    ),
  );
}

void _labDetails(
    BuildContext ctx, DuneConfig cfg, MockVideo v) {
  showModalBottomSheet(
    context: ctx,
    backgroundColor: cfg.surface,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: cfg.ink
                              .withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(2)))),
              const SizedBox(height: 14),
              for (final r in [
                (Icons.description_outlined, 'File',
                    'sunset_at_the_marina.mp4'),
                (Icons.folder_outlined, 'Location',
                    'Movies / Travel'),
                (Icons.schedule_outlined, 'Duration',
                    v.duration),
                (Icons.tv_outlined, 'Resolution',
                    '1920 × 1080'),
                (Icons.storage_outlined, 'Size', '1.4 GB'),
              ])
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 7),
                  child: Row(children: [
                    Icon(r.$1,
                        color:
                            cfg.ink.withValues(alpha: 0.55),
                        size: 18),
                    const SizedBox(width: 12),
                    Text(r.$2,
                        style: TextStyle(
                            fontSize: 13,
                            color: cfg.ink
                                .withValues(alpha: 0.55))),
                    const Spacer(),
                    Flexible(
                        child: Text(r.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cfg.ink))),
                  ]),
                ),
            ]),
      ),
    ),
  );
}

void _labRename(BuildContext ctx, DuneConfig cfg, String cur,
    ValueChanged<String> onRename) {
  final ctrl = TextEditingController(text: cur);
  showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: cfg.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22)),
      title: Text('Rename video',
          style: TextStyle(
              fontWeight: FontWeight.w800, color: cfg.ink)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: TextStyle(color: cfg.ink),
        decoration: InputDecoration(
          hintText: 'Video title',
          filled: true,
          fillColor: cfg.soft.withValues(alpha: 0.4),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(
                    color: cfg.ink.withValues(alpha: 0.6)))),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: cfg.accent),
          onPressed: () {
            final t = ctrl.text.trim();
            if (t.isNotEmpty) onRename(t);
            Navigator.of(ctx).pop();
          },
          child: const Text('Rename'),
        ),
      ],
    ),
  );
}

/// One share + save/rename/details row shared by all concepts.
class _LabActions extends StatelessWidget {
  final DuneConfig cfg;
  final MockVideo v;
  final String title;
  final bool fav;
  final VoidCallback onFav;
  final ValueChanged<String> onRename;
  const _LabActions(
      {required this.cfg,
      required this.v,
      required this.title,
      required this.fav,
      required this.onFav,
      required this.onRename});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, String l, VoidCallback t,
        {Color? c}) {
      return Expanded(
        child: GestureDetector(
          onTap: t,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: cfg.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: cfg.ink.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ]),
                child: Icon(i, color: c ?? cfg.ink, size: 20),
              ),
              const SizedBox(height: 4),
              Text(l,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cfg.ink.withValues(alpha: 0.6))),
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      btn(fav ? Icons.favorite : Icons.favorite_border,
          fav ? 'Saved' : 'Save', onFav,
          c: fav ? const Color(0xFFFF6B5E) : null),
      btn(Icons.ios_share, 'Share',
          () => _labShare(context, cfg, title)),
      btn(Icons.edit, 'Rename',
          () => _labRename(context, cfg, title, onRename)),
      btn(Icons.info_outline, 'Details',
          () => _labDetails(context, cfg, v)),
    ]);
  }
}

class _LabScaffold extends StatelessWidget {
  final DuneConfig cfg;
  final String title;
  final MockVideo v;
  final List<Widget> body;
  final Widget? trailing;
  const _LabScaffold(
      {required this.cfg,
      required this.title,
      required this.v,
      required this.body,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cfg.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle),
                  child: Icon(Icons.arrow_back,
                      color: cfg.ink, size: 21),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cfg.ink))),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ]),
            const SizedBox(height: 12),
            ...body,
          ],
        ),
      ),
    );
  }
}

// ============ CONCEPT 1 — ORBIT ============
// Progress is a ring around play. Drag the ring to seek.

class _OrbitPlayer extends StatefulWidget {
  final DuneConfig cfg;
  final int index;
  const _OrbitPlayer({required this.cfg, required this.index});
  @override
  State<_OrbitPlayer> createState() => _OrbitPlayerState();
}

class _OrbitPlayerState extends State<_OrbitPlayer> {
  late final MockSession s = MockSession();
  String? customTitle;
  bool fav = false;
  MockVideo get v =>
      mockVideos[widget.index % mockVideos.length];

  @override
  void initState() {
    super.initState();
    s.toggle();
  }

  @override
  void dispose() {
    s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    final title = customTitle ?? v.title;
    return _LabScaffold(
      cfg: cfg,
      title: title,
      v: v,
      body: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: MockArtwork(
                  video: v, radius: 0, glyph: false)),
        ),
        const SizedBox(height: 6),
        // orbit cluster
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(children: [
              _orbBtn(cfg, Icons.skip_previous,
                  () => _jump(-1)),
              const SizedBox(height: 10),
              _orbBtn(cfg, Icons.replay_10,
                  () => s.seekTo(s.pos - 10)),
            ]),
            const SizedBox(width: 18),
            GestureDetector(
              onPanUpdate: (d) => _ringSeek(d.localPosition),
              child: AnimatedBuilder(
                animation: s,
                builder: (_, __) => CustomPaint(
                  painter: _OrbitPainter(
                      frac: s.dur == 0
                          ? 0
                          : s.pos / s.dur,
                      track:
                          cfg.ink.withValues(alpha: 0.14),
                      accent: cfg.accent),
                  child: SizedBox(
                    width: 172,
                    height: 172,
                    child: Center(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => s.toggle()),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                              color: cfg.accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: cfg.accent
                                        .withValues(
                                            alpha: 0.4),
                                    blurRadius: 20,
                                    offset:
                                        const Offset(0, 8))
                              ]),
                          child: Icon(
                              s.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 34),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Column(children: [
              _orbBtn(cfg, Icons.skip_next, () => _jump(1)),
              const SizedBox(height: 10),
              _orbBtn(cfg, Icons.forward_10,
                  () => s.seekTo(s.pos + 10)),
            ]),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: s,
          builder: (_, __) => Center(
            child: Text(
                '${mockTime(s.pos)}  ·  ${mockTime(s.dur)}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ],
                    color: cfg.ink.withValues(alpha: 0.55))),
          ),
        ),
        const SizedBox(height: 8),
        _LabActions(
            cfg: cfg,
            v: v,
            title: title,
            fav: fav,
            onFav: () => setState(() => fav = !fav),
            onRename: (t) =>
                setState(() => customTitle = t)),
        const SizedBox(height: 6),
        _LabSpeeds(cfg: cfg, s: s),
        const SizedBox(height: 14),
        const DuneSectionTitle('Up next'),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final idx = (widget.index + 1 + i) %
                  mockVideos.length;
              final m = mockVideos[idx];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DuneScope(
                          config: cfg,
                          child: _OrbitPlayer(
                              cfg: cfg, index: idx))));
                },
                child: SizedBox(
                  width: 168,
                  child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: MockArtwork(
                                video: m, radius: 14)),
                        const SizedBox(height: 5),
                        Text(m.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cfg.ink)),
                      ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _ringSeek(Offset local) {
    // ring box is 172×172
    final f = _angleFraction(
        local, const Size(172, 172));
    s.seekTo(f * s.dur);
  }

  void _jump(int d) {
    final n =
        (widget.index + d) % mockVideos.length;
    final idx = n < 0 ? n + mockVideos.length : n;
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            DuneScope(config: widget.cfg, child: _OrbitPlayer(cfg: widget.cfg, index: idx))));
  }

  Widget _orbBtn(
      DuneConfig cfg, IconData i, VoidCallback t) {
    return GestureDetector(
      onTap: t,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
            color: cfg.surface, shape: BoxShape.circle),
        child: Icon(i, color: cfg.ink, size: 21),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double frac;
  final Color track;
  final Color accent;
  _OrbitPainter(
      {required this.frac,
      required this.track,
      required this.accent});
  @override
  void paint(Canvas c, Size size) {
    final ctr = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    c.drawCircle(
        ctr,
        r,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);
    c.drawArc(
        Rect.fromCircle(center: ctr, radius: r),
        -math.pi / 2,
        frac * 2 * math.pi,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_OrbitPainter o) =>
      o.frac != frac;
}

// ============ CONCEPT 2 — CHAPTERS ============
// The video as a document: timecoded chapters to jump through.

class _ChaptersPlayer extends StatefulWidget {
  final DuneConfig cfg;
  final int index;
  const _ChaptersPlayer(
      {required this.cfg, required this.index});
  @override
  State<_ChaptersPlayer> createState() =>
      _ChaptersPlayerState();
}

const _chapters = [
  (0.0, 'Cold open', 'the hook in 40 seconds'),
  (12.0, 'The drive in', 'roads, fuel, playlists'),
  (34.0, 'Golden hour', 'the light does the work'),
  (58.0, 'Detour', 'wrong turn, right story'),
  (78.0, 'Credits walk', 'where it all lands'),
];

class _ChaptersPlayerState extends State<_ChaptersPlayer> {
  late final MockSession s = MockSession()..dur = 92;
  String? customTitle;
  bool fav = false;
  MockVideo get v =>
      mockVideos[widget.index % mockVideos.length];

  @override
  void initState() {
    super.initState();
    s.toggle();
  }

  @override
  void dispose() {
    s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    final title = customTitle ?? v.title;
    return _LabScaffold(
      cfg: cfg,
      title: title,
      v: v,
      body: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                MockArtwork(
                    video: v, radius: 0, glyph: false),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(children: [
                    _miniGlass(Icons.replay_10,
                        () => s.seekTo(s.pos - 10)),
                    const SizedBox(width: 8),
                    AnimatedBuilder(
                      animation: s,
                      builder: (_, __) => GestureDetector(
                        onTap: () =>
                            setState(() => s.toggle()),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle),
                          child: Icon(
                              s.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: cfg.ink,
                              size: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _miniGlass(Icons.forward_10,
                        () => s.seekTo(s.pos + 10)),
                  ]),
                ),
              ])),
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: s,
          builder: (_, __) {
            var active = 0;
            for (var i = 0;
                i < _chapters.length;
                i++) {
              if (s.pos >= _chapters[i].$1) active = i;
            }
            return Column(
              children: [
                for (var i = 0;
                    i < _chapters.length;
                    i++)
                  _chapter(cfg, i, active, _chapters[i]),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        _LabActions(
            cfg: cfg,
            v: v,
            title: title,
            fav: fav,
            onFav: () => setState(() => fav = !fav),
            onRename: (t) =>
                setState(() => customTitle = t)),
        const SizedBox(height: 6),
        _LabSpeeds(cfg: cfg, s: s),
      ],
    );
  }

  Widget _chapter(DuneConfig cfg, int i, int active,
      (double, String, String) ch) {
    final on = i == active;
    final done = i < active;
    return GestureDetector(
      onTap: () => s.seekTo(ch.$1),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: on ? cfg.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: on
                  ? cfg.accent.withValues(alpha: 0.5)
                  : cfg.ink.withValues(alpha: 0.12)),
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: on
                  ? cfg.accent
                  : done
                      ? cfg.accent.withValues(alpha: 0.25)
                      : cfg.soft.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
                on
                    ? Icons.pause
                    : done
                        ? Icons.check
                        : Icons.play_arrow,
                color: on
                    ? Colors.white
                    : cfg.ink.withValues(alpha: 0.7),
                size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(ch.$2,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: cfg.ink)),
                  Text(ch.$3,
                      style: TextStyle(
                          fontSize: 12,
                          color: cfg.ink
                              .withValues(alpha: 0.5))),
                ]),
          ),
          Text(
              mockTime(ch.$1),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [
                    FontFeature.tabularFigures()
                  ],
                  color: on
                      ? cfg.accent
                      : cfg.ink.withValues(alpha: 0.45))),
        ]),
      ),
    );
  }

  Widget _miniGlass(IconData i, VoidCallback t) {
    return GestureDetector(
      onTap: t,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle),
        child: Icon(i, color: Colors.white, size: 19),
      ),
    );
  }
}

// ============ CONCEPT 3 — TIDEFORM ============
// Waveform scrubbing: drag the tide to move through time.

class _TideformPlayer extends StatefulWidget {
  final DuneConfig cfg;
  final int index;
  final bool flip;
  final bool shuffle;
  final int repeat;
  const _TideformPlayer(
      {required this.cfg,
      required this.index,
      this.flip = false,
      this.shuffle = false,
      this.repeat = 0});
  @override
  State<_TideformPlayer> createState() =>
      _TideformPlayerState();
}

class _TideformPlayerState extends State<_TideformPlayer> {
  late final MockSession s = MockSession();
  String? customTitle;
  bool fav = false;
  bool _flip = false; // up next on top
  bool _muted = false;
  bool _shuffle = false;
  int _repeat = 0; // 0 off · 1 all · 2 one
  List<int> _order = const [];
  MockVideo get v =>
      mockVideos[widget.index % mockVideos.length];
  static const bars = 56;

  /// Deterministic per-video shape: seeded by video, so every video
  /// gets its own stable tide — but it is decorative, not analysed.
  int get _seed => widget.index * 131 + v.title.length * 17;
  double _barH(int i) =>
      0.22 + 0.78 * (((i * 37 + _seed * 101) % 29) / 29);

  List<int> _naturalOrder() => [
        for (var i = 0; i < 4; i++)
          (widget.index + 1 + i) % mockVideos.length
      ];

  @override
  void initState() {
    super.initState();
    _flip = widget.flip;
    _shuffle = widget.shuffle;
    _repeat = widget.repeat;
    _order = _naturalOrder();
    if (_shuffle) _order.shuffle();
    s.onEnded = () {
      if (!mounted) return;
      if (_repeat == 2) {
        s.seekTo(0);
        if (!s.playing) setState(() => s.toggle());
      } else if (_repeat == 1) {
        _jump(1);
      }
    };
    s.toggle();
  }

  @override
  void dispose() {
    s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    final title = customTitle ?? v.title;
    final mainSec = <Widget>[
      _videoStack(cfg),
      const SizedBox(height: 14),
      _timeRow(cfg),
      const SizedBox(height: 8),
      _transportRow(cfg),
      const SizedBox(height: 12),
    ];
    final restSec = <Widget>[
      _waveCard(cfg),
      const SizedBox(height: 4),
      Center(
        child: Text('drag the tide to scrub',
            style: TextStyle(
                fontSize: 11,
                color: cfg.ink.withValues(alpha: 0.4))),
      ),
      const SizedBox(height: 10),
      _LabActions(
          cfg: cfg,
          v: v,
          title: title,
          fav: fav,
          onFav: () => setState(() => fav = !fav),
          onRename: (t) =>
              setState(() => customTitle = t)),
      const SizedBox(height: 6),
      _LabSpeeds(cfg: cfg, s: s),
      const SizedBox(height: 14),
    ];
    final nextSec = <Widget>[
      Row(children: [
        Text('Up next',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: cfg.ink)),
        const Spacer(),
        _queueBtn(
            cfg,
            Icons.shuffle,
            _shuffle,
            () => setState(() {
              _shuffle = !_shuffle;
              _order = _shuffle
                  ? (_naturalOrder()..shuffle())
                  : _naturalOrder();
            })),
        const SizedBox(width: 8),
        _queueBtn(
            cfg,
            _repeat == 2
                ? Icons.repeat_one
                : Icons.repeat,
            _repeat != 0,
            () => setState(() =>
                _repeat = (_repeat + 1) % 3)),
      ]),
      const SizedBox(height: 8),
      SizedBox(
        height: 132,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _order.length,
          separatorBuilder: (_, __) =>
              const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final idx = _order[i];
            final m = mockVideos[idx];
            return GestureDetector(
              onTap: () => _jump(i + 1),
              child: SizedBox(
                width: 150,
                child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: MockArtwork(
                              video: m, radius: 14)),
                      const SizedBox(height: 5),
                      Text(m.title,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w700,
                              color: cfg.ink)),
                    ]),
              ),
            );
          },
        ),
      ),
    ];
    return _LabScaffold(
      cfg: cfg,
      title: title,
      v: v,
      trailing: _headBtn(cfg,
          _flip ? Icons.swap_vert : Icons.swap_vert, () {
        setState(() => _flip = !_flip);
      }),
      body: _flip
          ? [...nextSec, ...mainSec, ...restSec]
          : [...mainSec, ...restSec, ...nextSec],
    );
  }

  Widget _headBtn(
      DuneConfig cfg, IconData i, VoidCallback t) {
    return GestureDetector(
      onTap: t,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cfg.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: cfg.ink.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(i, color: cfg.ink, size: 20),
      ),
    );
  }

  /// Video with mute (top-right) + fullscreen (bottom-right) glass.
  Widget _videoStack(DuneConfig cfg,
      {bool hideOverlays = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(fit: StackFit.expand, children: [
          MockArtwork(
              video: v, radius: 0, glyph: false),
          if (!hideOverlays) ...[
            Positioned(
              top: 10,
              right: 10,
              child: _glass(IconstateMute(),
                  () => setState(() => _muted = !_muted)),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child:
                  _glass(Icons.fullscreen, _goFull),
            ),
          ],
        ]),
      ),
    );
  }

  IconData IconstateMute() =>
      _muted ? Icons.volume_off : Icons.volume_up;

  Widget _glass(IconData i, VoidCallback t) {
    return GestureDetector(
      onTap: t,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle),
        child: Icon(i, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _timeRow(DuneConfig cfg) {
    return AnimatedBuilder(
      animation: s,
      builder: (_, __) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(mockTime(s.pos),
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ],
                    color: cfg.ink)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text('/ ${mockTime(s.dur)}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          cfg.ink.withValues(alpha: 0.45))),
            ),
          ]),
    );
  }

  Widget _transportRow(DuneConfig cfg) {
    return AnimatedBuilder(
      animation: s,
      builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _tBtn(cfg, Icons.skip_previous,
                () => _jump(-1),
                d: 44,
                icon: 20),
            const SizedBox(width: 8),
            _tBtn(cfg, Icons.replay_10,
                () => s.seekTo(s.pos - 10)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => s.toggle()),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                    color: cfg.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: cfg.accent
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset:
                              const Offset(0, 8))
                    ]),
                child: Icon(
                    s.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 32),
              ),
            ),
            const SizedBox(width: 12),
            _tBtn(cfg, Icons.forward_10,
                () => s.seekTo(s.pos + 10)),
            const SizedBox(width: 8),
            _tBtn(cfg, Icons.skip_next, () => _jump(1),
                d: 44, icon: 20),
          ]),
    );
  }

  Widget _waveCard(DuneConfig cfg) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) =>
          _waveSeek(d.localPosition, context),
      onTapDown: (d) =>
          _waveSeek(d.localPosition, context),
      child: Container(
        key: _waveKey,
        height: 108,
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cfg.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedBuilder(
          animation: s,
          builder: (_, __) {
            final f =
                s.dur == 0 ? 0.0 : s.pos / s.dur;
            return Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < bars; i++)
                  Builder(builder: (_) {
                    final bf = i / bars;
                    final near =
                        (bf - f).abs() < 0.035;
                    return Expanded(
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(
                                horizontal: 1.5),
                        height: 80 * _barH(i),
                        decoration: BoxDecoration(
                          color: near
                              ? cfg.accent2
                              : bf <= f
                                  ? cfg.accent
                                  : cfg.ink.withValues(
                                      alpha: 0.14),
                          borderRadius:
                              BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  final _waveKey = GlobalKey();

  void _waveSeek(Offset local, BuildContext context) {
    final box = _waveKey.currentContext
        ?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final w = box.size.width - 28; // padding
    final f =
        ((local.dx - 14) / w).clamp(0.0, 1.0);
    s.seekTo(f * s.dur);
  }

  void _jump(int d) {
    final n =
        (widget.index + d) % mockVideos.length;
    final idx = n < 0 ? n + mockVideos.length : n;
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DuneScope(
            config: widget.cfg,
            child: _TideformPlayer(
                cfg: widget.cfg,
                index: idx,
                flip: _flip,
                shuffle: _shuffle,
                repeat: _repeat))));
  }

  void _goFull() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _TideFullPage(
              s: s,
              cfg: widget.cfg,
              v: v,
              title: customTitle ?? v.title,
              muted: _muted,
              onMute: () =>
                  setState(() => _muted = !_muted),
            )));
  }

  Widget _queueBtn(DuneConfig cfg, IconData i, bool on,
      VoidCallback t) {
    return GestureDetector(
      onTap: t,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: on
              ? cfg.accent
              : cfg.soft.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(i,
            color: on
                ? Colors.white
                : cfg.ink.withValues(alpha: 0.6),
            size: 18),
      ),
    );
  }

  Widget _tBtn(DuneConfig cfg, IconData i, VoidCallback t,
      {double d = 48, double icon = 22}) {
    return GestureDetector(
      onTap: t,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
            color: cfg.surface, shape: BoxShape.circle),
        child: Icon(i, color: cfg.ink, size: icon),
      ),
    );
  }
}

// ============ REAL FULLSCREEN (landscape + immersive) ============

class _TideFullPage extends StatefulWidget {
  final MockSession s;
  final DuneConfig cfg;
  final MockVideo v;
  final String title;
  final bool muted;
  final VoidCallback onMute;
  const _TideFullPage(
      {required this.s,
      required this.cfg,
      required this.v,
      required this.title,
      required this.muted,
      required this.onMute});

  @override
  State<_TideFullPage> createState() =>
      _TideFullPageState();
}

class _TideFullPageState extends State<_TideFullPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MockArtwork(
              video: widget.v,
              radius: 0,
              glyph: false),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(children: [
              _fBtn(Icons.fullscreen_exit,
                  () => Navigator.of(context).pop()),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                                color: Colors.black54,
                                blurRadius: 8)
                          ]))),
              _fBtn(
                  widget.muted
                      ? Icons.volume_off
                      : Icons.volume_up,
                  widget.onMute),
            ]),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 18,
            child: AnimatedBuilder(
              animation: s,
              builder: (_, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Text(mockTime(s.pos),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [
                                FontFeature
                                    .tabularFigures()
                              ])),
                      Expanded(
                        child: SliderTheme(
                          data:
                              const SliderThemeData(
                            trackHeight: 3,
                            thumbShape:
                                RoundSliderThumbShape(
                                    enabledThumbRadius:
                                        6),
                            activeTrackColor:
                                Colors.white,
                            inactiveTrackColor:
                                Color(0x4DFFFFFF),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value:
                                s.pos.clamp(0, s.dur),
                            max: s.dur,
                            onChanged: (v) =>
                                s.seekTo(v),
                          ),
                        ),
                      ),
                      Text(mockTime(s.dur),
                          style: TextStyle(
                              color: Colors.white
                                  .withValues(
                                      alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          _fBtn(Icons.skip_previous,
                              () {}),
                          const SizedBox(width: 14),
                          _fBtn(Icons.replay_10, () {
                            s.seekTo(s.pos - 10);
                          }),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () => setState(
                                () => s.toggle()),
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                  color: widget
                                      .cfg.accent,
                                  shape:
                                      BoxShape.circle),
                              child: Icon(
                                  s.playing
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28),
                            ),
                          ),
                          const SizedBox(width: 14),
                          _fBtn(Icons.forward_10, () {
                            s.seekTo(s.pos + 10);
                          }),
                          const SizedBox(width: 14),
                          _fBtn(Icons.skip_next, () {}),
                        ]),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fBtn(IconData i, VoidCallback t) {
    return GestureDetector(
      onTap: t,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Center(
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8)
              ],
            ),
            child:
                Icon(i, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

// ============ CONCEPT 4 — DIAL ============
// A jog dial for the thumb: rotate the tick ring to seek.

class _DialPlayer extends StatefulWidget {
  final DuneConfig cfg;
  final int index;
  const _DialPlayer(
      {required this.cfg, required this.index});
  @override
  State<_DialPlayer> createState() => _DialPlayerState();
}

class _DialPlayerState extends State<_DialPlayer> {
  late final MockSession s = MockSession();
  String? customTitle;
  bool fav = false;
  MockVideo get v =>
      mockVideos[widget.index % mockVideos.length];
  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    s.toggle();
  }

  @override
  void dispose() {
    s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    final title = customTitle ?? v.title;
    return _LabScaffold(
      cfg: cfg,
      title: title,
      v: v,
      body: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
              aspectRatio: 16 / 8,
              child: MockArtwork(
                  video: v, radius: 0, glyph: false)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dBtn(cfg, Icons.replay_10,
                () => s.seekTo(s.pos - 10)),
            const SizedBox(width: 20),
            GestureDetector(
              onPanUpdate: (d) => _dialSeek(d),
              child: AnimatedBuilder(
                animation: s,
                builder: (_, __) => CustomPaint(
                  painter: _TicksPainter(
                      frac: s.dur == 0
                          ? 0
                          : s.pos / s.dur,
                      track:
                          cfg.ink.withValues(alpha: 0.15),
                      accent: cfg.accent),
                  child: SizedBox(
                    width: 208,
                    height: 208,
                    child: Center(
                      child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => setState(
                                  () => s.toggle()),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                    color: cfg.ink,
                                    shape:
                                        BoxShape.circle),
                                child: Icon(
                                    s.playing
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: cfg.bg,
                                    size: 30),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                mockTime(s.pos),
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w800,
                                    fontFeatures:
                                        const [
                                      FontFeature
                                          .tabularFigures()
                                    ],
                                    color: cfg.ink)),
                            GestureDetector(
                              onTap: _cycleSpeed,
                              child: Container(
                                margin:
                                    const EdgeInsets.only(
                                        top: 4),
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                        horizontal: 12,
                                        vertical: 5),
                                decoration: BoxDecoration(
                                    color: cfg.accent
                                        .withValues(
                                            alpha: 0.15),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                10)),
                                child: Text(
                                    '${s.speed}x · tap',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                        color:
                                            cfg.accent)),
                              ),
                            ),
                          ]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            _dBtn(cfg, Icons.forward_10,
                () => s.seekTo(s.pos + 10)),
          ],
        ),
        Center(
          child: Text('rotate the ring to seek',
              style: TextStyle(
                  fontSize: 11,
                  color: cfg.ink.withValues(alpha: 0.4))),
        ),
        const SizedBox(height: 8),
        _LabActions(
            cfg: cfg,
            v: v,
            title: title,
            fav: fav,
            onFav: () => setState(() => fav = !fav),
            onRename: (t) =>
                setState(() => customTitle = t)),
        const SizedBox(height: 12),
        const DuneSectionTitle('Up next'),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final idx = (widget.index + 1 + i) %
                  mockVideos.length;
              final m = mockVideos[idx];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DuneScope(
                          config: cfg,
                          child: _DialPlayer(
                              cfg: cfg, index: idx))));
                },
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MockArtwork(
                            video: m, radius: 14),
                        Positioned(
                            right: 6,
                            bottom: 6,
                            child: MockDurationBadge(
                                m.duration)),
                      ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Jog-dial feel: relative drag distance moves through time.
  void _dialSeek(DragUpdateDetails d) {
    final f =
        (s.pos / s.dur) + d.delta.dx / 220 - d.delta.dy / 220;
    s.seekTo(f.clamp(0.0, 1.0) * s.dur);
  }

  void _cycleSpeed() {
    final i = _speeds.indexOf(s.speed);
    s.setSpeed(_speeds[(i + 1) % _speeds.length]);
  }

  Widget _dBtn(
      DuneConfig cfg, IconData i, VoidCallback t) {
    return GestureDetector(
      onTap: t,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            color: cfg.surface, shape: BoxShape.circle),
        child: Icon(i, color: cfg.ink, size: 22),
      ),
    );
  }
}

class _TicksPainter extends CustomPainter {
  final double frac;
  final Color track;
  final Color accent;
  _TicksPainter(
      {required this.frac,
      required this.track,
      required this.accent});
  @override
  void paint(Canvas c, Size size) {
    final ctr = Offset(size.width / 2, size.height / 2);
    const n = 60;
    for (var i = 0; i < n; i++) {
      final a = (i / n) * 2 * math.pi - math.pi / 2;
      final on = (i / n) <= frac;
      final p1 = ctr +
          Offset(math.cos(a), math.sin(a)) *
              (size.width / 2 - 6);
      final p2 = ctr +
          Offset(math.cos(a), math.sin(a)) *
              (size.width / 2 - (on ? 20 : 14));
      c.drawLine(
          p1,
          p2,
          Paint()
            ..color = on ? accent : track
            ..strokeWidth = on ? 4 : 2.5
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_TicksPainter o) =>
      o.frac != frac;
}

/// Compact speed pills shared by concepts.
class _LabSpeeds extends StatelessWidget {
  final DuneConfig cfg;
  final MockSession s;
  const _LabSpeeds({required this.cfg, required this.s});
  static const _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: s,
      builder: (_, __) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          Icon(Icons.schedule_outlined,
              color: cfg.ink.withValues(alpha: 0.45),
              size: 16),
          const SizedBox(width: 8),
          for (final sp in _speeds) ...[
            GestureDetector(
              onTap: () => s.setSpeed(sp),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: (s.speed == sp)
                      ? cfg.accent
                      : cfg.soft.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${sp}x',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: (s.speed == sp)
                            ? Colors.white
                            : cfg.ink
                                .withValues(alpha: 0.6))),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ]),
      ),
    );
  }
}
