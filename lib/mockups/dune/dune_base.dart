import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../mockup_data.dart';

/// ============================================================
/// DUNE — the shared visual engine for all 5 mockups.
///
/// One config drives colours, radii, nav style and player
/// geometry. Sibling style files only supply content + config.
/// ============================================================

class DuneConfig {
  final Color bg;
  final Color surface;
  final Color ink;
  final Color accent;
  final Color accent2;
  final Color soft;
  final Color blobA;
  final Color blobB;
  final double radius;
  final int tabStyle; // 0 = bottom pill, 1 = top chips, 2 = side rail
  final int playerMode; // 0 = inset card, 1 = fullbleed, 2 = dock
  final bool dark;
  final String wordmark;
  final String sub;

  const DuneConfig({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.accent,
    required this.accent2,
    required this.soft,
    required this.blobA,
    required this.blobB,
    required this.radius,
    required this.tabStyle,
    required this.playerMode,
    required this.dark,
    required this.wordmark,
    required this.sub,
  });
}

class DuneScope extends InheritedWidget {
  final DuneConfig config;
  const DuneScope({super.key, required this.config, required super.child});

  static DuneConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DuneScope>()!.config;

  @override
  bool updateShouldNotify(DuneScope old) => old.config != config;
}

/// Small pill chip.
class DuneChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const DuneChip(
      {super.key,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cfg = DuneScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: active ? cfg.accent : cfg.soft.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: active
                    ? Colors.white
                    : cfg.ink.withValues(alpha: 0.65))),
      ),
    );
  }
}

/// Section heading with optional note.
class DuneSectionTitle extends StatelessWidget {
  final String title;
  final String? note;
  const DuneSectionTitle(this.title, {super.key, this.note});

  @override
  Widget build(BuildContext context) {
    final cfg = DuneScope.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: cfg.ink)),
        if (note != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    color: cfg.ink.withValues(alpha: 0.45))),
          ),
        ],
      ],
    );
  }
}

/// Home shell: blobs + header + tabbed body + nav.
class DuneHome extends StatefulWidget {
  final DuneConfig cfg;
  final Widget Function(BuildContext) header;
  final Widget Function(BuildContext) explore;
  final Widget Function(BuildContext) saved;
  final Widget Function(BuildContext) search;
  const DuneHome({
    super.key,
    required this.cfg,
    required this.header,
    required this.explore,
    required this.saved,
    required this.search,
  });

  @override
  State<DuneHome> createState() => _DuneHomeState();
}

class _DuneHomeState extends State<DuneHome> {
  int tab = 0;
  static const _labels = ['Browse', 'Saved', 'Search'];
  static const _icons = [
    HugeIcons.strokeRoundedHome01,
    HugeIcons.strokeRoundedFavourite,
    HugeIcons.strokeRoundedSearch01,
  ];

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    return Scaffold(
      backgroundColor: cfg.bg,
      body: Stack(
        children: [
          Positioned(top: -80, right: -70, child: _blob(cfg.blobA, 230)),
          Positioned(bottom: 120, left: -90, child: _blob(cfg.blobB, 250)),
          SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cfg.tabStyle == 2) _rail(cfg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.header(context),
                      if (cfg.tabStyle == 1) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            itemCount: 3,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) => DuneChip(
                              label: _labels[i],
                              active: tab == i,
                              onTap: () =>
                                  setState(() => tab = i),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Expanded(
                        child: IndexedStack(
                          index: tab,
                          children: [
                            widget.explore(context),
                            widget.saved(context),
                            widget.search(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (cfg.tabStyle == 0)
            Positioned(
                left: 0, right: 0, bottom: 14, child: _pillNav(cfg)),
        ],
      ),
    );
  }

  Widget _blob(Color c, double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            c.withValues(alpha: 0.55),
            c.withValues(alpha: 0),
          ]),
        ),
      );

  Widget _pillNav(DuneConfig cfg) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cfg.surface,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
                color: cfg.ink.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              GestureDetector(
                onTap: () => setState(() => tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color:
                        tab == i ? cfg.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: _ThinIcon(
                    icon: _icons[i],
                    color: tab == i
                        ? Colors.white
                        : cfg.ink.withValues(alpha: 0.55),
                    size: 19,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _rail(DuneConfig cfg) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 90, 0, 90),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: cfg.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: cfg.ink.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(6, 0))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 6, horizontal: 4),
              child: GestureDetector(
                onTap: () => setState(() => tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: tab == i
                        ? cfg.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _ThinIcon(
                    icon: _icons[i],
                    color: tab == i
                        ? Colors.white
                        : cfg.ink.withValues(alpha: 0.55),
                    size: 19,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
/// Same HugeIcons glyphs, thin 1.5px strokes — the refined look.
/// Used for every control in the mockup engine.
class _ThinIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color? color;
  final double size;
  const _ThinIcon(
      {required this.icon, this.color, this.size = 20});

  @override
  Widget build(BuildContext context) => HugeIcon(
      icon: icon, color: color, size: size, strokeWidth: 1.5);
}

/// Push the shared mock player for [index].
void openDunePlayer(BuildContext context, DuneConfig cfg, int index) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => DuneScope(
      config: cfg,
      child: _DunePlayer(cfg: cfg, index: index),
    ),
  ));
}

class _DunePlayer extends StatefulWidget {
  final DuneConfig cfg;
  final int index;
  const _DunePlayer({required this.cfg, required this.index});

  @override
  State<_DunePlayer> createState() => _DunePlayerState();
}

class _DunePlayerState extends State<_DunePlayer> {
  late final MockSession s = MockSession();
  bool chrome = true;
  Timer? hide;
  String? customTitle;
  bool fav = false;

  MockVideo get video =>
      mockVideos[widget.index % mockVideos.length];
  String get title => customTitle ?? video.title;

  @override
  void initState() {
    super.initState();
    s.toggle(); // autoplay the mock
    _armHide();
  }

  void _armHide() {
    hide?.cancel();
    hide = Timer(const Duration(seconds: 3), () {
      if (mounted && s.playing) setState(() => chrome = false);
    });
  }

  void _poke() {
    if (!chrome) setState(() => chrome = true);
    _armHide();
  }

  @override
  void dispose() {
    hide?.cancel();
    s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.cfg;
    final darkText = cfg.dark ? Colors.white : cfg.ink;
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cfg.bg,
        colorScheme: ColorScheme(
          brightness: cfg.dark ? Brightness.dark : Brightness.light,
          primary: cfg.accent,
          onPrimary: Colors.white,
          secondary: cfg.accent2,
          onSecondary: cfg.ink,
          surface: cfg.surface,
          onSurface: cfg.ink,
          error: const Color(0xFFB3261E),
          onError: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: cfg.bg,
        body: SafeArea(
          child: cfg.playerMode == 1
              ? _fullbleed(context, cfg, darkText)
              : cfg.playerMode == 2
                  ? _dock(context, cfg, darkText)
                  : _inset(context, cfg, darkText),
        ),
      ),
    );
  }

  // ============ MODE 0 — inset card ============

  Widget _inset(BuildContext context, DuneConfig cfg, Color t) {
    final v = video;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            _iconBtn(context, cfg, Icons.arrow_back,
                () => Navigator.of(context).pop()),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: t)),
            ),
            _iconBtn(context, cfg, Icons.more_horiz,
                _moreSheet),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() {
            chrome = !chrome;
            if (chrome) _armHide();
          }),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cfg.radius),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MockArtwork(
                      video: v, radius: 0, glyph: false),
                  if (chrome)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _scrimControls(cfg),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _actionsRow(context, cfg),
        const SizedBox(height: 10),
        _speedRow(cfg),
        const SizedBox(height: 16),
        _upNext(context, cfg),
      ],
    );
  }

  // ============ MODE 1 — fullbleed ============

  Widget _fullbleed(BuildContext context, DuneConfig cfg, Color t) {
    final v = video;
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() {
            chrome = !chrome;
            if (chrome) _armHide();
          }),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MockArtwork(
                    video: v, radius: 0, glyph: false),
                if (chrome)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          12, 8, 12, 8),
                      child: Row(
                        children: [
                          _glassBtn(Icons.arrow_back,
                              () => Navigator.of(context)
                                  .pop()),
                          const Spacer(),
                          _glassBtn(
                              Icons.closed_caption_outlined,
                              () {}),
                          const SizedBox(width: 8),
                          _glassBtn(Icons.fullscreen,
                              () {}),
                        ],
                      ),
                    ),
                  ),
                if (chrome)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _scrimControls(cfg),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: t)),
              Text(v.meta,
                  style: TextStyle(
                      fontSize: 13,
                      color: t.withValues(alpha: 0.55))),
              const SizedBox(height: 4),
              _actionsRow(context, cfg),
              const SizedBox(height: 10),
              _speedRow(cfg),
              const SizedBox(height: 16),
              _upNext(context, cfg),
            ],
          ),
        ),
      ],
    );
  }

  // ============ MODE 2 — dock ============

  Widget _dock(BuildContext context, DuneConfig cfg, Color t) {
    final v = video;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cfg.surface,
            borderRadius: BorderRadius.circular(cfg.radius),
            boxShadow: [
              BoxShadow(
                  color: cfg.ink.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  chrome = !chrome;
                  if (chrome) _armHide();
                }),
                child: SizedBox(
                  width: 148,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MockArtwork(
                            video: v,
                            radius: 12,
                            glyph: false),
                        Center(
                          child: AnimatedBuilder(
                            animation: s,
                            builder: (_, __) =>
                                GestureDetector(
                              onTap: () {
                                setState(
                                    () => s.toggle());
                                _armHide();
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.all(
                                        10),
                                decoration: BoxDecoration(
                                  color: Colors.black
                                      .withValues(
                                          alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  s.playing
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: t)),
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: s,
                      builder: (_, __) => ClipRRect(
                        borderRadius:
                            BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: s.dur == 0
                              ? 0
                              : s.pos / s.dur,
                          minHeight: 4,
                          color: cfg.accent,
                          backgroundColor: cfg.ink
                              .withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _miniBtn(cfg, Icons.replay_10,
                            () {
                          s.seekTo(s.pos - 10);
                          _armHide();
                        }),
                        const SizedBox(width: 8),
                        AnimatedBuilder(
                          animation: s,
                          builder: (_, __) => _miniBtn(
                              cfg,
                              s.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              () {
                            setState(() => s.toggle());
                            _armHide();
                          }),
                        ),
                        const SizedBox(width: 8),
                        _miniBtn(cfg, Icons.forward_10,
                            () {
                          s.seekTo(s.pos + 10);
                          _armHide();
                        }),
                        const Spacer(),
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pop(),
                          child: Icon(Icons.close,
                              color:
                                  t.withValues(alpha: 0.5),
                              size: 17),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              _actionsRow(context, cfg),
              const SizedBox(height: 10),
              _speedRow(cfg),
              const SizedBox(height: 14),
              _upNext(context, cfg),
            ],
          ),
        ),
      ],
    );
  }

  // ============ scrim transport (sits ON the video) ============

  /// Floating transport: time + slim slider + small icons
  /// straight on the video — no backdrop, halo only.
  Widget _scrimControls(DuneConfig cfg) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: AnimatedBuilder(
        animation: s,
        builder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(mockTime(s.pos),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              color: Colors.black54,
                              blurRadius: 6)
                        ],
                        fontFeatures: [
                          FontFeature.tabularFigures()
                        ])),
                Expanded(
                  child: SliderTheme(
                    data: const SliderThemeData(
                      trackHeight: 3,
                      thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 6),
                      overlayShape:
                          RoundSliderOverlayShape(
                              overlayRadius: 12),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor:
                          Color(0x4DFFFFFF),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: s.pos.clamp(0, s.dur),
                      max: s.dur,
                      onChanged: (v) => s.seekTo(v),
                      onChangeEnd: (_) => _armHide(),
                    ),
                  ),
                ),
                Text(mockTime(s.dur),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white
                            .withValues(alpha: 0.85),
                        shadows: const [
                          Shadow(
                              color: Colors.black54,
                              blurRadius: 6)
                        ],
                        fontFeatures: const [
                          FontFeature.tabularFigures()
                        ])),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                _scrubBtn(Icons.skip_previous,
                    () => _jumpVideo(-1)),
                _scrubBtn(
                    Icons.replay_10,
                    () {
                  s.seekTo(s.pos - 10);
                  _poke();
                }),
                GestureDetector(
                  onTap: () {
                    setState(() => s.toggle());
                    _poke();
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cfg.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Icon(
                      s.playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                _scrubBtn(
                    Icons.forward_10,
                    () {
                  s.seekTo(s.pos + 10);
                  _poke();
                }),
                _scrubBtn(Icons.skip_next,
                    () => _jumpVideo(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Small haloed button straight on the video — no backdrop.
  Widget _scrubBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.4),
                    blurRadius: 8)
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  void _jumpVideo(int dir) {
    final n = (widget.index + dir) % mockVideos.length;
    final idx = n < 0 ? n + mockVideos.length : n;
    Navigator.of(context).pop();
    openDunePlayer(context, widget.cfg, idx);
  }

  // ============ actions: favourite / share / rename / details ============

  Widget _actionsRow(BuildContext context, DuneConfig cfg) {
    return Row(
      children: [
        _action(context, cfg,
            icon: fav ? Icons.favorite : Icons.favorite_border,
            label: fav ? 'Saved' : 'Save',
            tint: fav ? const Color(0xFFFF6B5E) : null,
            onTap: () => setState(() => fav = !fav)),
        _action(context, cfg,
            icon: Icons.ios_share,
            label: 'Share',
            onTap: _shareSheet),
        _action(context, cfg,
            icon: Icons.edit,
            label: 'Rename',
            onTap: _renameDialog),
        _action(context, cfg,
            icon: Icons.info_outline,
            label: 'Details',
            onTap: _detailsSheet),
      ],
    );
  }

  Widget _action(BuildContext context, DuneConfig cfg,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? tint}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cfg.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color:
                            cfg.ink.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Icon(icon,
                    color: tint ?? cfg.ink, size: 22),
              ),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cfg.ink.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }

  void _shareSheet() {
    final cfg = widget.cfg;
    showModalBottomSheet(
      context: context,
      backgroundColor: cfg.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cfg.ink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Share “$title”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cfg.ink)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _shareOpt(cfg, Icons.ios_share,
                      'Share file',
                      'send the video itself'),
                  _shareOpt(cfg, Icons.content_copy,
                      'Copy title',
                      'title to clipboard'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _shareOpt(cfg, Icons.link,
                      'Copy path',
                      'file location'),
                  _shareOpt(cfg, Icons.file_download_outlined,
                      'Save copy',
                      'duplicate locally'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareOpt(DuneConfig cfg, IconData icon,
      String label, String sub) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Mock — $label (not wired)'),
                duration: const Duration(seconds: 1)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cfg.soft.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: cfg.accent,
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: cfg.ink)),
              Text(sub,
                  style: TextStyle(
                      fontSize: 11,
                      color: cfg.ink.withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
    );
  }

  void _moreSheet() {
    final cfg = widget.cfg;
    showModalBottomSheet(
      context: context,
      backgroundColor: cfg.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cfg.ink.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              _sheetRow(cfg, Icons.closed_caption_outlined,
                  'Captions',
                  'English · off', () {
                Navigator.of(context).pop();
              }),
              _sheetRow(cfg, Icons.lock_outline,
                  'Lock controls', 'kids mode', () {
                Navigator.of(context).pop();
              }),
              _sheetRow(cfg, Icons.info_outline,
                  'Details',
                  'size · format · path', () {
                Navigator.of(context).pop();
                _detailsSheet();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetRow(DuneConfig cfg, IconData icon,
      String label, String sub, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: cfg.soft.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: cfg.ink, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w700, color: cfg.ink)),
      subtitle: Text(sub,
          style: TextStyle(
              color: cfg.ink.withValues(alpha: 0.5))),
      onTap: onTap,
    );
  }

  void _renameDialog() {
    final cfg = widget.cfg;
    final ctrl = TextEditingController(text: title);
    showDialog(
      context: context,
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
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: TextStyle(
                    color: cfg.ink.withValues(alpha: 0.6))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: cfg.accent),
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isNotEmpty) {
                setState(() => customTitle = t);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _detailsSheet() {
    final cfg = widget.cfg;
    final v = video;
    showModalBottomSheet(
      context: context,
      backgroundColor: cfg.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
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
                    color: cfg.ink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: MockArtwork(
                            video: v, radius: 12)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: cfg.ink)),
                        Text(v.meta,
                            style: TextStyle(
                                fontSize: 13,
                                color: cfg.ink.withValues(
                                    alpha: 0.55))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow(cfg, Icons.description_outlined,
                  'File name', '${_slug(title)}.mp4'),
              _detailRow(cfg, Icons.folder_outlined,
                  'Location', 'Movies / Travel'),
              _detailRow(cfg, Icons.schedule_outlined,
                  'Duration', v.duration),
              _detailRow(cfg, Icons.tv_outlined,
                  'Resolution', '1920 × 1080'),
              _detailRow(
                  cfg,
                  Icons.storage_outlined,
                  'Size',
                  '1.4 GB'),
              _detailRow(
                  cfg,
                  Icons.calendar_month_outlined,
                  'Added',
                  '12 Mar 2026'),
            ],
          ),
        ),
      ),
    );
  }

  String _slug(String t) =>
      t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  Widget _detailRow(DuneConfig cfg, IconData icon,
      String k, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cfg.soft.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: cfg.ink, size: 19),
          ),
          const SizedBox(width: 12),
          Text(k,
              style: TextStyle(
                  fontSize: 13,
                  color: cfg.ink.withValues(alpha: 0.55))),
          const Spacer(),
          Flexible(
            child: Text(val,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cfg.ink)),
          ),
        ],
      ),
    );
  }

  // ============ supporting rows ============

  Widget _speedRow(DuneConfig cfg) {
    const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    return AnimatedBuilder(
      animation: s,
      builder: (_, __) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Icon(Icons.schedule_outlined,
                color: cfg.ink.withValues(alpha: 0.45),
                size: 17),
            const SizedBox(width: 8),
            for (final sp in speeds) ...[
              GestureDetector(
                onTap: () => s.setSpeed(sp),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
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
          ],
        ),
      ),
    );
  }

  Widget _upNext(BuildContext context, DuneConfig cfg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DuneSectionTitle('Up next'),
        const SizedBox(height: 8),
        for (var i = 0; i < 4; i++)
          Builder(builder: (_) {
            final idx =
                (widget.index + 1 + i) % mockVideos.length;
            final v = mockVideos[idx];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                openDunePlayer(context, cfg, idx);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 104,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MockArtwork(video: v, radius: 12),
                            Positioned(
                              right: 5,
                              bottom: 5,
                              child:
                                  MockDurationBadge(v.duration),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(v.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: cfg.ink)),
                          Text(v.meta,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cfg.ink.withValues(
                                      alpha: 0.5))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _iconBtn(BuildContext context, DuneConfig cfg,
      IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: cfg.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: cfg.ink.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon, color: cfg.ink, size: 22),
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _miniBtn(
      DuneConfig cfg, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: cfg.soft.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: cfg.ink, size: 18),
      ),
    );
  }
}
