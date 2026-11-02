import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/core/mushaf/mushaf_sheet_layout.dart';
import 'package:quran_offline/core/mushaf/mushaf_warmup.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_geometry.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_shader.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_snapshot.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_mushaf_layout.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_sheet.dart';
import 'package:quran_offline/features/read/widgets/mushaf_paper.dart';

/// Dev-only app shell for the Curl Lab (see `curl_lab_main.dart`).
class CurlLabApp extends StatefulWidget {
  const CurlLabApp({super.key});

  @override
  State<CurlLabApp> createState() => _CurlLabAppState();
}

class _CurlLabAppState extends State<CurlLabApp> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    final scheme =
        _dark ? AppColors.darkColorScheme() : AppColors.lightColorScheme();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      home: CurlLabScreen(
        dark: _dark,
        onToggleDark: () => setState(() => _dark = !_dark),
      ),
    );
  }
}

/// One turn the lab can show: spreads are listed left to right.
class _LabTurn {
  const _LabTurn(this.label, this.current, this.next, {required this.forward});

  final String label;
  final List<int> current;
  final List<int> next;
  final bool forward;

  bool get single => current.length == 1;

  /// Index of the moving sheet in [current] and of its back in [next].
  int get leafIndex => single || forward ? 0 : 1;
  int get backIndex => single ? 0 : (forward ? 1 : 0);

  int get frontPage => current[leafIndex];
  int get backPage => next[backIndex];
}

const _turns = [
  _LabTurn('1|2 → 3|4', [2, 1], [4, 3], forward: true),
  _LabTurn('49|50 → 51|52', [50, 49], [52, 51], forward: true),
  _LabTurn('603|604 → 601|602', [604, 603], [602, 601], forward: false),
  _LabTurn('single 3 → 4', [3], [4], forward: true),
];

/// Pages the snapshot step must show as plain images.
const _snapshotPages = [2, 3, 50, 51, 603, 604];

enum _LabStep { snapshots, checker, curl }

/// Holds the sheet layout of each live spread, recorded during layout.
class _LayoutHolder {
  MushafSheetLayout? current;
  MushafSheetLayout? next;
}

class CurlLabScreen extends StatefulWidget {
  const CurlLabScreen({
    super.key,
    required this.dark,
    required this.onToggleDark,
  });

  final bool dark;
  final VoidCallback onToggleDark;

  @override
  State<CurlLabScreen> createState() => _CurlLabScreenState();
}

class _CurlLabScreenState extends State<CurlLabScreen>
    with SingleTickerProviderStateMixin {
  final Map<int, QpcV2PageContent> _contents = {};
  double _openingScale = 1;
  final _currentKey = GlobalKey(debugLabel: 'labCurrent');
  final _nextKey = GlobalKey(debugLabel: 'labNext');
  final _layouts = _LayoutHolder();

  ui.FragmentShader? _shader;
  String? _shaderError;

  _LabStep _step = _LabStep.snapshots;
  int _turnIndex = 0;

  /// Captured page images (by page number) with their ink coverage.
  final Map<int, ui.Image> _pageImages = {};
  final Map<int, double> _pageInk = {};
  bool _capturing = false;
  bool _captured = false;
  String _status = 'loading pages…';

  ui.Image? _checkerFront;
  ui.Image? _checkerBack;

  // Finger controls (leaf space, as shares of the free edge / page height).
  double _t = 0.35;
  double _fingerY = 0.7;
  double _grabY = 0.9;
  double _radiusFactor = kPageCurlRadiusFactor;
  Offset? _dragGrab;
  Offset? _dragFinger;

  late final AnimationController _auto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..addListener(() => setState(() {}));
  bool _autoRunning = false;

  _LabTurn get _turn => _turns[_turnIndex];

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      final program = await loadPageCurlProgram();
      _shader = program.fragmentShader();
      logPageCurl('lab: shader loaded');
    } catch (error) {
      _shaderError = '$error';
      logPageCurl('lab: shader failed: $error');
    }
    await MushafWarmup.ensureInitialized();
    final layout = QpcV2MushafLayout(QpcV2MushafLayout.sharedRepository());
    final pages = {
      for (final turn in _turns) ...turn.current,
      for (final turn in _turns) ...turn.next,
      1,
      2,
    };
    for (final page in pages) {
      // Awaits the page's QPC V2 font before returning.
      _contents[page] = await layout.getPageContent(page);
    }
    _openingScale = computeOpeningPageScale(
      lines: [_contents[1]!, _contents[2]!].expand(
        (page) => page.lines
            .where((l) => l.isAyah && l.glyphText.isNotEmpty)
            .map((l) => (
                  glyphText: l.glyphText,
                  fontFamily: page.fontFamily,
                  justify: false,
                )),
      ),
    );
    if (!mounted) return;
    setState(() => _status = 'pages loaded');
    await _captureAll();
  }

  @override
  void dispose() {
    _auto.dispose();
    _shader?.dispose();
    for (final image in _pageImages.values) {
      image.dispose();
    }
    _checkerFront?.dispose();
    _checkerBack?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- capture

  Future<void> _captureAll() async {
    for (var i = 0; i < _turns.length; i++) {
      await _captureTurn(i);
    }
    if (mounted) setState(() => _turnIndex = 0);
    await _captureTurn(0);
  }

  /// Shows [index]'s two spreads live, waits for paint, then rasterizes them.
  Future<void> _captureTurn(int index) async {
    if (!mounted) return;
    setState(() {
      _turnIndex = index;
      _capturing = true;
      _captured = false;
      _status = 'capturing ${_turns[index].label}…';
    });
    final started = DateTime.now();
    await waitForPaintedFrame();
    if (!mounted) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final turn = _turns[index];
    final paper = MushafPaperPalette.of(Theme.of(context).colorScheme).sheet;
    for (final (key, pages, layout) in [
      (_currentKey, turn.current, _layouts.current),
      (_nextKey, turn.next, _layouts.next),
    ]) {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || layout == null) {
        _status = 'capture failed: boundary not ready';
        logPageCurl('lab: $_status');
        continue;
      }
      final crops = captureSheetSnapshots(
        boundary,
        layout.sheets,
        pixelRatio: dpr,
      );
      for (var i = 0; i < pages.length; i++) {
        final page = pages[i];
        _pageImages.remove(page)?.dispose();
        _pageImages[page] = crops[i];
        // Ink is measured inside the text box only: the frame alone must
        // never pass as a painted page.
        final text = layout.texts[i].shift(-layout.sheets[i].topLeft);
        _pageInk[page] = await snapshotInkCoverage(
          crops[i],
          paper: paper,
          within: Rect.fromLTRB(
            text.left * dpr,
            text.top * dpr,
            text.right * dpr,
            text.bottom * dpr,
          ),
        );
      }
    }
    final ms = DateTime.now().difference(started).inMilliseconds;
    final bytes = _pageImages.values.fold<int>(0, (a, i) => a + imageBytes(i));
    final front = _pageInk[turn.frontPage] ?? 0;
    final back = _pageInk[turn.backPage] ?? 0;
    final ok = pageSnapshotInkIsValid(front) && pageSnapshotInkIsValid(back);
    logPageCurl(
      'lab: ${turn.label} captured in ${ms}ms, '
      'front p${turn.frontPage} ink ${(front * 100).toStringAsFixed(1)}%, '
      'back p${turn.backPage} ink ${(back * 100).toStringAsFixed(1)}%, '
      'cache ${(bytes / 1048576).toStringAsFixed(1)} MB',
    );
    if (!mounted) return;
    setState(() {
      _capturing = false;
      _captured = ok;
      _status = ok
          ? '${turn.label}: ready in ${ms}ms · '
              'cache ${(bytes / 1048576).toStringAsFixed(1)} MB'
          : '${turn.label}: INVALID snapshot → would fall back to slide';
    });
  }

  Future<void> _ensureChecker(Size leafSize, double dpr) async {
    if (_checkerFront != null) return;
    _checkerFront = _checkerImage(leafSize, dpr, 'FRONT', Colors.indigo);
    _checkerBack = _checkerImage(leafSize, dpr, 'BACK', Colors.deepOrange);
  }

  /// Checkerboard with orientation markers: red top-left, blue bottom-right.
  ui.Image _checkerImage(Size size, double dpr, String label, Color tint) {
    final w = (size.width * dpr).round();
    final h = (size.height * dpr).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final cell = w / 8;
    for (var y = 0; y * cell < h; y++) {
      for (var x = 0; x < 8; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell, cell),
          Paint()
            ..color = (x + y).isEven ? Colors.white : tint.withValues(alpha: 0.55),
        );
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cell, cell),
      Paint()..color = Colors.red,
    );
    canvas.drawRect(
      Rect.fromLTWH(w - cell, h - cell, cell, cell),
      Paint()..color = Colors.blue,
    );
    final text = TextPainter(
      text: TextSpan(
        text: '$label ↑',
        style: TextStyle(
          color: Colors.black,
          fontSize: w / 7,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset((w - text.width) / 2, h * 0.2));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(w, h);
    picture.dispose();
    return image;
  }

  // ------------------------------------------------------------------ curl

  PageCurlLeaf? _leafFor(MushafSheetLayout? layout) {
    if (layout == null) return null;
    final sheets = layout.sheets;
    return sheets.length == 2
        ? PageCurlLeaf.spread(
            left: sheets[0],
            right: sheets[1],
            forward: _turn.forward,
          )
        : PageCurlLeaf.single(sheets[0]);
  }

  PageCurlFrame _frameFor(PageCurlLeaf leaf) {
    if (_autoRunning) {
      final t = Curves.easeOut.transform(_auto.value);
      return computePageCurl(
        leaf: leaf,
        grab: pageCurlAutoGrab(leaf),
        finger: pageCurlAutoFinger(leaf, t),
        radiusFactor: _radiusFactor,
      );
    }
    if (_dragGrab != null && _dragFinger != null) {
      return computePageCurl(
        leaf: leaf,
        grab: _dragGrab!,
        finger: _dragFinger!,
        radiusFactor: _radiusFactor,
      );
    }
    final edge = leaf.freeEdge;
    return computePageCurl(
      leaf: leaf,
      grab: Offset(edge, _grabY * leaf.height),
      finger: Offset(edge - 2 * edge * _t, _fingerY * leaf.height),
      radiusFactor: _radiusFactor,
    );
  }

  Future<void> _runAuto() async {
    setState(() => _autoRunning = true);
    await _auto.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _autoRunning = false);
  }

  Widget _spread(List<int> pages, GlobalKey key, bool current) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      key: key,
      child: MushafFramedSheets(
        pages: pages,
        focus: true,
        legacyVerticalChrome: 0,
        onLayout: (layout) =>
            current ? _layouts.current = layout : _layouts.next = layout,
        pageBuilder: (page) => MushafPageSheet(
          content: _contents[page]!,
          openingPageScale: page <= 2 ? _openingScale : 1,
          colorScheme: scheme,
          ayahKeys: Map<String, GlobalKey>.of(const {}),
        ),
      ),
    );
  }

  /// Live next spread below, live current spread clipped to the page that
  /// stays, the shader leaf on top.
  Widget _curlStage() {
    final turn = _turn;
    if (turn.current.any((p) => !_contents.containsKey(p)) ||
        turn.next.any((p) => !_contents.containsKey(p))) {
      return const Center(child: CircularProgressIndicator());
    }
    final front = _pageImages[turn.frontPage];
    final back = _pageImages[turn.backPage];
    final curling = _captured && !_capturing && _shader != null;
    return GestureDetector(
      onPanStart: (d) {
        final leaf = _leafFor(_layouts.current);
        if (leaf == null) return;
        final local = leaf.toLeaf(d.localPosition);
        setState(() {
          _dragGrab = Offset(leaf.freeEdge, local.dy);
          _dragFinger = local;
        });
      },
      onPanUpdate: (d) {
        final leaf = _leafFor(_layouts.current);
        if (leaf == null) return;
        setState(() => _dragFinger = leaf.toLeaf(d.localPosition));
      },
      onPanEnd: (_) => setState(() {
        _dragGrab = null;
        _dragFinger = null;
      }),
      child: Stack(
        children: [
          Positioned.fill(child: _spread(turn.next, _nextKey, false)),
          Positioned.fill(
            child: ClipRect(
              clipper: _StayClipper(
                layouts: _layouts,
                enabled: curling,
                forward: turn.forward,
                single: turn.single,
              ),
              child: _spread(turn.current, _currentKey, true),
            ),
          ),
          if (curling && front != null && back != null)
            Positioned.fill(
              child: Builder(
                builder: (context) => CustomPaint(
                  painter: _LabCurlPainter(
                    shader: _shader!,
                    leafOf: () => _leafFor(_layouts.current),
                    frameOf: _frameFor,
                    front: front,
                    back: back,
                    dark: widget.dark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _checkerStage() {
    final shader = _shader;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final pageW = size.width * 0.42;
        final pageH = math.min(size.height * 0.9, pageW * 1.45);
        final top = (size.height - pageH) / 2;
        final left = Rect.fromLTWH(size.width / 2 - pageW - 4, top, pageW, pageH);
        final right = Rect.fromLTWH(size.width / 2 + 4, top, pageW, pageH);
        unawaited(_ensureChecker(left.size, dpr));
        final leaf = PageCurlLeaf.spread(left: left, right: right, forward: true);
        return Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: Colors.grey.shade300)),
            Positioned.fromRect(rect: left, child: const _Placeholder('UNDER')),
            Positioned.fromRect(rect: right, child: const _Placeholder('STAY')),
            if (shader != null && _checkerFront != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _LabCurlPainter(
                    shader: shader,
                    leafOf: () => leaf,
                    frameOf: _frameFor,
                    front: _checkerFront!,
                    back: _checkerBack!,
                    dark: false,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _snapshotGrid() {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            for (final page in _snapshotPages)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text(
                        'p$page · ink '
                        '${((_pageInk[page] ?? 0) * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _pageImages[page] == null
                            ? const Center(child: Text('—'))
                            : RawImage(
                                image: _pageImages[page],
                                fit: BoxFit.contain,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = switch (_step) {
      // The live spreads must stay in the tree (and painted) while capturing.
      _LabStep.snapshots when _capturing => _curlStage(),
      _LabStep.snapshots => _snapshotGrid(),
      _LabStep.checker => _checkerStage(),
      _LabStep.curl => _curlStage(),
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  SegmentedButton<_LabStep>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: _LabStep.snapshots,
                        label: Text('1 Snapshots'),
                      ),
                      ButtonSegment(
                        value: _LabStep.checker,
                        label: Text('2 Checker'),
                      ),
                      ButtonSegment(value: _LabStep.curl, label: Text('3 Curl')),
                    ],
                    selected: {_step},
                    onSelectionChanged: (s) => setState(() => _step = s.first),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _turnIndex,
                    items: [
                      for (var i = 0; i < _turns.length; i++)
                        DropdownMenuItem(value: i, child: Text(_turns[i].label)),
                    ],
                    onChanged: _capturing
                        ? null
                        : (i) => i == null ? null : unawaited(_captureTurn(i)),
                  ),
                  IconButton(
                    tooltip: 'Recapture',
                    onPressed: _capturing ? null : () => _captureAll(),
                    icon: const Icon(Icons.camera_alt_outlined),
                  ),
                  IconButton(
                    tooltip: 'Animated turn',
                    onPressed: _autoRunning ? null : _runAuto,
                    icon: const Icon(Icons.play_arrow),
                  ),
                  IconButton(
                    tooltip: 'Light / dark',
                    onPressed: () {
                      widget.onToggleDark();
                      // Paper colour changed: the snapshots are stale.
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => unawaited(_captureAll()),
                      );
                    },
                    icon: Icon(
                      widget.dark ? Icons.light_mode : Icons.dark_mode,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _shaderError ?? _status,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: stage),
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  _slider('t', _t, (v) => _t = v),
                  _slider('finger y', _fingerY, (v) => _fingerY = v,
                      min: -0.2, max: 1.2),
                  _slider('grab y', _grabY, (v) => _grabY = v),
                  _slider('radius', _radiusFactor, (v) => _radiusFactor = v,
                      min: 0.04, max: 0.16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    ValueChanged<double> onChanged, {
    double min = 0,
    double max = 1,
  }) {
    return Expanded(
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text('$label ${value.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.labelSmall),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: (v) => setState(() => onChanged(v)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps only the page that stays (the half without the leaf) once curling.
class _StayClipper extends CustomClipper<Rect> {
  _StayClipper({
    required this.layouts,
    required this.enabled,
    required this.forward,
    required this.single,
  });

  final _LayoutHolder layouts;
  final bool enabled;
  final bool forward;
  final bool single;

  @override
  Rect getClip(Size size) {
    final layout = layouts.current;
    if (!enabled || layout == null) return Offset.zero & size;
    if (single) return Rect.zero;
    final hinge = (layout.sheets[0].right + layout.sheets[1].left) / 2;
    return forward
        ? Rect.fromLTRB(hinge, 0, size.width, size.height)
        : Rect.fromLTRB(0, 0, hinge, size.height);
  }

  @override
  bool shouldReclip(_StayClipper oldClipper) => true;
}

class _LabCurlPainter extends CustomPainter {
  _LabCurlPainter({
    required this.shader,
    required this.leafOf,
    required this.frameOf,
    required this.front,
    required this.back,
    required this.dark,
  });

  final ui.FragmentShader shader;
  final PageCurlLeaf? Function() leafOf;
  final PageCurlFrame Function(PageCurlLeaf leaf) frameOf;
  final ui.Image front;
  final ui.Image back;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final leaf = leafOf();
    if (leaf == null) return;
    PageCurlPainter(
      shader: shader,
      leaf: leaf,
      frame: frameOf(leaf),
      front: front,
      back: back,
      dark: dark,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_LabCurlPainter oldDelegate) => true;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: label == 'STAY' ? const Color(0xFFE3F2FD) : const Color(0xFFE8F5E9),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
