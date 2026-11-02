import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:quran_offline/core/mushaf/mushaf_sheet_layout.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_geometry.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_shader.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_snapshot.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_stats.dart';

/// How the stage changes pages.
enum MushafTurnStyle {
  /// Printed-book leaf turn (falls back to a slide per turn when it can't run).
  curl,

  /// Instant page change.
  none,
}

/// Share of the turn region at each outer edge where a tap turns the page.
const double kMushafTurnEdgeZone = 0.12;

/// Progress a drag must pass to complete a turn on release.
const double kMushafTurnCommit = 0.35;

/// Horizontal fling speed (logical px/s) that completes a turn either way.
const double kMushafTurnFlingVelocity = 600;

/// Full turn duration (interactive release, tap, audio).
const Duration kMushafTurnDuration = Duration(milliseconds: 400);

/// Longest a turn may take to finish when the next one is already queued.
const Duration kMushafTurnChainFinish = Duration(milliseconds: 120);

/// Idle time after a turn settles before neighbours are rasterized.
const Duration kMushafTurnPrewarmDelay = Duration(milliseconds: 300);

/// Idle time before pages two away are built ahead of time.
const Duration kMushafTurnPrebuildDelay = Duration(milliseconds: 700);

/// Longest an auto turn waits for a missing snapshot before it slides.
const Duration kMushafTurnSnapshotWait = Duration(milliseconds: 150);

/// Snapshot memory cap (bytes).
const int kMushafTurnCacheBudget = 40 * 1024 * 1024;

/// Leaf raster scale relative to the device pixel ratio.
const double kMushafLeafRasterScale =
    String.fromEnvironment('QO_LEAF_SCALE') == '0.75' ? 0.75 : 1.0;

/// What one pager item tells the stage about its turn region.
///
/// Items find it through [MushafTurnScope]; outside the stage (Geser, tests,
/// goldens) there is no scope and every hook is a no-op.
class MushafTurnSlot {
  MushafTurnSlot._(this.index, this._stage);

  final int index;
  final _MushafTurnStageState _stage;
  final GlobalKey boundaryKey = GlobalKey(debugLabel: 'mushafTurnRegion');

  /// Sheet rects of a framed region (null: the whole region is one page).
  MushafSheetLayout? layout;

  final Set<int> _readyPages = {};

  /// Bumped every time the item rebuilds its page content; snapshots of an
  /// older generation are stale.
  int generation = 0;

  /// True once the content of [generation] has been painted.
  bool painted = false;

  bool _framePending = false;

  /// A page body built its content (called during build).
  void pageReady(int pageNo) {
    _readyPages.add(pageNo);
    generation++;
    painted = false;
    if (_readyPages.length < _stage._pagesPerSlot || _framePending) return;
    _framePending = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _framePending = false;
      painted = true;
      _stage._onSlotPainted(this);
    });
  }

  /// A tap on an empty part of the item. True when the stage turned the page
  /// (or refused to at a bound); false lets the item toggle its bars.
  bool handleTap(Offset globalPosition) =>
      _stage._handleEdgeTap(this, globalPosition);

  RenderSnapshotBoundary? get boundary {
    final object = boundaryKey.currentContext?.findRenderObject();
    return object is RenderSnapshotBoundary && object.attached && object.hasSize
        ? object
        : null;
  }
}

/// Gives the widgets of one pager item access to its [MushafTurnSlot].
class MushafTurnScope extends InheritedWidget {
  const MushafTurnScope({super.key, required this.slot, required super.child});

  final MushafTurnSlot slot;

  static MushafTurnSlot? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MushafTurnScope>()?.slot;

  @override
  bool updateShouldNotify(MushafTurnScope oldWidget) => slot != oldWidget.slot;
}

/// Marks the part of a pager item that turns (the sheets, or the phone page).
///
/// Inside a turn stage it becomes a repaint boundary the stage rasterizes;
/// elsewhere it returns [child] unchanged.
class MushafTurnRegion extends StatelessWidget {
  const MushafTurnRegion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final slot = MushafTurnScope.maybeOf(context);
    if (slot == null) return child;
    return SnapshotBoundary(key: slot.boundaryKey, child: child);
  }
}

/// Programmatic page changes (audio follow-along, jumps).
class MushafTurnController {
  _MushafTurnStageState? _state;

  int? get index => _state?._index;

  /// Turns to [index]: an animated turn for a neighbour, a jump otherwise.
  void animateTo(int index) => _state?._animateTo(index);

  void jumpTo(int index) => _state?._jumpTo(index);
}

/// Pager for the "Lembar" (curl) and "Tanpa" (none) page-turn settings.
///
/// Index order follows the book: index + 1 is the next page/spread, turned by
/// a drag to the RIGHT (RTL). The current item and its neighbours stay live in
/// a stack; hidden ones are clipped away so they cost nothing to composite.
///
/// A turn between items k and k + 1 is always the same physical leaf: its
/// front is k's left sheet (or page k), its back is k + 1's right sheet (or
/// page k + 1). Turning forward runs it from progress 0 to 1, turning back
/// from 1 to 0, so the snapshots of one turn serve both directions.
class MushafTurnStage extends StatefulWidget {
  const MushafTurnStage({
    super.key,
    required this.itemCount,
    required this.initialIndex,
    required this.spread,
    required this.style,
    required this.itemBuilder,
    required this.onIndexChanged,
    required this.paperColor,
    this.itemsKey,
    this.controller,
  });

  final int itemCount;
  final int initialIndex;

  /// Items are two-page spreads (else one page each).
  final bool spread;
  final MushafTurnStyle style;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Called when a turn settles on another item (not during the turn).
  final void Function(int index, {required bool programmatic}) onIndexChanged;

  /// Paper colour of the turn region, for snapshot validation.
  final Color paperColor;

  /// Everything the items show besides their index (bars, selection, ...).
  /// Items are rebuilt only when it changes: rebuilding a live page is the
  /// most expensive thing a turn could trigger, and it makes snapshots stale.
  final Object? itemsKey;
  final MushafTurnController? controller;

  @override
  State<MushafTurnStage> createState() => _MushafTurnStageState();
}

enum _Side { left, right, single }

class _Snapshot {
  _Snapshot(this.image, this.generation);

  final ui.Image image;
  final int generation;
  bool validated = false;

  int get bytes => imageBytes(image);
}

/// One turn in flight between items [a] and [a] + 1.
class _Turn {
  _Turn({
    required this.a,
    required this.topIsA,
    required this.region,
    required this.stageWidth,
    this.leaf,
    this.front,
    this.back,
  });

  final int a;
  int get b => a + 1;

  /// The item the turn started on is drawn on top (with a hole for the leaf).
  final bool topIsA;

  /// Turn region in stage coordinates.
  final Rect region;

  /// Stage width (slide distance).
  final double stageWidth;

  /// Null for a slide fallback.
  final PageCurlLeaf? leaf;
  final ui.Image? front;
  final ui.Image? back;

  bool get curl => leaf != null;

  // Curl: leaf-space grab point and finger. Slide: [slide] 0 (a) .. 1 (b).
  Offset grab = Offset.zero;
  Offset finger = Offset.zero;
  double slide = 0;

  /// Where the current animation ends (true: settle on b).
  bool? targetB;

  double get progress => curl
      ? computePageCurl(leaf: leaf!, grab: grab, finger: finger).progress
      : slide;

  /// How far the turn has gone for the commit decision: the free edge's
  /// travel over one page (single: the leaf lands past the spine, off the
  /// screen) or over the spread.
  double commitProgress({required bool spread}) {
    if (!curl) return slide;
    final edge = leaf!.freeEdge;
    final travel = spread ? 2 * edge : edge;
    return ((edge - finger.dx) / travel).clamp(0.0, 1.0);
  }

  Offset get landing => Offset(-leaf!.freeEdge, grab.dy);
  Offset get rest => Offset(leaf!.freeEdge, grab.dy);
}

class _MushafTurnStageState extends State<MushafTurnStage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int _index = widget.initialIndex;
  final Map<int, MushafTurnSlot> _slots = {};
  final Set<int> _window = {};
  final Map<String, _Snapshot> _cache = {};
  final Map<int, Widget> _items = {};

  ui.FragmentShader? _shader;
  bool _shaderFailed = false;

  _Turn? _turn;
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: kMushafTurnDuration,
  )
    ..addListener(_onAnimTick)
    ..addStatusListener(_onAnimStatus);
  Offset Function(double t)? _fingerAt;
  double Function(double t)? _slideAt;

  /// One queued turn: +1 forward, -1 back.
  int? _pending;
  bool _programmatic = false;

  // Drag state.
  Offset? _dragStart;
  Offset _dragStartFinger = Offset.zero;
  double _dragStartSlide = 0;
  bool _dragIgnored = false;
  bool _dragChained = false;

  final ValueNotifier<int> _tick = ValueNotifier(0);
  Timer? _prewarmTimer;
  Timer? _prebuildTimer;
  Size? _lastSize;
  ColorScheme? _lastScheme;
  final PageTurnStats _stats = PageTurnStats();

  int get _pagesPerSlot => widget.spread ? 2 : 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?._state = this;
    _resetWindow();
    if (widget.style == MushafTurnStyle.curl) unawaited(_loadShader());
  }

  Future<void> _loadShader() async {
    try {
      final program = await loadPageCurlProgram();
      if (!mounted) return;
      _shader = program.fragmentShader();
      _warmUpShader();
    } catch (error) {
      _shaderFailed = true;
      logPageCurl('shader unavailable, turns slide: $error');
    }
  }

  /// Draws the leaf once off screen so the GPU pipeline is compiled before
  /// the first real turn instead of during its first frame.
  void _warmUpShader() {
    final shader = _shader;
    if (shader == null) return;
    final recorder = ui.PictureRecorder();
    final pixel = (() {
      final r = ui.PictureRecorder();
      Canvas(r).drawRect(
        const Rect.fromLTWH(0, 0, 4, 4),
        Paint()..color = widget.paperColor,
      );
      final picture = r.endRecording();
      final image = picture.toImageSync(4, 4);
      picture.dispose();
      return image;
    })();
    const leaf = PageCurlLeaf(rect: Rect.fromLTWH(0, 0, 16, 16), hingeX: 16, side: 1);
    PageCurlPainter(
      shader: shader,
      leaf: leaf,
      frame: computePageCurl(
        leaf: leaf,
        grab: const Offset(16, 8),
        finger: const Offset(4, 6),
      ),
      front: pixel,
      back: pixel,
      dark: false,
    ).paint(Canvas(recorder), const Size(16, 16));
    final picture = recorder.endRecording();
    picture.toImageSync(16, 16).dispose();
    picture.dispose();
    pixel.dispose();
  }

  @override
  void didUpdateWidget(MushafTurnStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The pager rebuilt (selection, chrome, settings): items follow.
    if (oldWidget.itemsKey != widget.itemsKey) _items.clear();
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
    if (oldWidget.style != widget.style &&
        widget.style == MushafTurnStyle.curl) {
      unawaited(_loadShader());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final sizeChanged = _lastSize != null && _lastSize != size;
    final themeChanged = _lastScheme != null && _lastScheme != scheme;
    _lastSize = size;
    _lastScheme = scheme;
    if (sizeChanged) {
      // Fold/unfold or rotation: drop the turn, keep the page.
      _cancelTurn('window resized');
      _clearCache('window resized');
    } else if (themeChanged) {
      _clearCache('theme changed');
    }
    _schedulePrewarm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _cancelTurn('app paused');
      _clearCache('app paused');
    } else if (state == AppLifecycleState.resumed) {
      _schedulePrewarm();
    }
  }

  @override
  void didHaveMemoryPressure() => _clearCache('memory pressure');

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller?._state == this) widget.controller?._state = null;
    _prewarmTimer?.cancel();
    _prebuildTimer?.cancel();
    _anim.dispose();
    _tick.dispose();
    _shader?.dispose();
    _clearCache(null);
    _stats.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- window

  bool _inBounds(int index) => index >= 0 && index < widget.itemCount;

  /// Live items: the current one and its neighbours, plus already built
  /// items up to three away (so turning back and forth never rebuilds one).
  void _resetWindow() {
    _window
      ..removeWhere((i) => (i - _index).abs() > 3)
      ..addAll([_index - 1, _index, _index + 1].where(_inBounds));
  }

  MushafTurnSlot _slot(int index) =>
      _slots.putIfAbsent(index, () => MushafTurnSlot._(index, this));

  void _onSlotPainted(MushafTurnSlot slot) {
    if (!mounted) return;
    _schedulePrewarm();
  }

  // -------------------------------------------------------------- cache

  String _key(int index, _Side side) => '$index:${side.name}';

  _Side get _frontSide => widget.spread ? _Side.left : _Side.single;
  _Side get _backSide => widget.spread ? _Side.right : _Side.single;

  /// Snapshot keys the turns out of [index] need (both directions).
  Set<String> _neededFor(int index) => {
        if (_inBounds(index + 1)) ...{
          _key(index, _frontSide),
          _key(index + 1, _backSide),
        },
        if (_inBounds(index - 1)) ...{
          _key(index - 1, _frontSide),
          _key(index, _backSide),
        },
      };

  int get _cacheBytes => _cache.values.fold(0, (sum, s) => sum + s.bytes);

  void _clearCache(String? reason) {
    if (_cache.isNotEmpty && reason != null) {
      logPageCurl('cache cleared ($reason): '
          '${(_cacheBytes / 1048576).toStringAsFixed(1)} MB');
    }
    for (final snapshot in _cache.values) {
      snapshot.image.dispose();
    }
    _cache.clear();
  }

  /// Sliding window: snapshots of the turns next to the current item stay
  /// (so flipping back and forth captures nothing new); others go, farthest
  /// first, once the cache is over budget or more than two items away.
  void _trimCache() {
    final keep = {
      ..._neededFor(_index),
      if (_pending != null) ..._neededFor(_index + _pending!),
    };
    int distance(String key) =>
        (int.parse(key.split(':').first) - _index).abs();
    _cache.removeWhere((key, snapshot) {
      if (keep.contains(key) || distance(key) <= 2) return false;
      snapshot.image.dispose();
      return true;
    });
    _makeRoom(0, keep);
    _stats.recordCache(_cacheBytes);
  }

  /// Evicts snapshots outside [keep], farthest first, until [incoming] more
  /// bytes fit in the budget.
  void _makeRoom(int incoming, Set<String> keep) {
    int distance(String key) =>
        (int.parse(key.split(':').first) - _index).abs();
    while (_cacheBytes + incoming > kMushafTurnCacheBudget) {
      final spare = _cache.keys.where((k) => !keep.contains(k)).toList()
        ..sort((a, b) => distance(b).compareTo(distance(a)));
      if (spare.isEmpty) break;
      _cache.remove(spare.first)!.image.dispose();
    }
  }

  /// A fresh snapshot of [index]'s [side], capturing it now if needed.
  ui.Image? _snapshot(int index, _Side side) {
    final slot = _slots[index];
    if (slot == null) return null;
    final key = _key(index, side);
    final cached = _cache[key];
    if (cached != null && cached.generation == slot.generation) {
      return cached.image;
    }
    if (!slot.painted) return null;
    final boundary = slot.boundary;
    if (boundary == null) return null;
    final rect = _sideRect(slot, side, boundary.size);
    if (rect == null) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context) * kMushafLeafRasterScale;
    _cache.remove(key)?.image.dispose();
    _makeRoom(
      ((rect.width * dpr).ceil() * (rect.height * dpr).ceil() * 4),
      {
        ..._neededFor(_index),
        if (_turn != null) ...{
          _key(_turn!.a, _frontSide),
          _key(_turn!.b, _backSide),
        },
      },
    );
    final watch = Stopwatch()..start();
    final image = boundary.captureRect(rect, pixelRatio: dpr);
    final captureMicros = watch.elapsedMicroseconds;
    _stats.recordCapture(captureMicros);
    if (const bool.fromEnvironment('QO_CAPTURE_BENCH')) {
      // Compare with the async path: time until the image is ready.
      final async = Stopwatch()..start();
      unawaited(
        boundary.captureRectAsync(rect, pixelRatio: dpr).then((full) {
          logPageCurl(
            'bench $key toImageSync ${captureMicros}us (UI), '
            'toImage ${async.elapsedMicroseconds}us (await)',
          );
          full.dispose();
        }),
      );
    }
    if (kProfileMode || kDebugMode) {
      logPageCurl(
        'capture $key ${cached == null ? 'missing' : 'stale g${cached.generation}->g${slot.generation}'} '
        '${captureMicros}us',
      );
    }
    _cache.remove(key)?.image.dispose();
    final snapshot = _Snapshot(image, slot.generation);
    _cache[key] = snapshot;
    unawaited(_validate(key, snapshot));
    _stats.recordCache(_cacheBytes);
    return image;
  }

  Rect? _sideRect(MushafTurnSlot slot, _Side side, Size regionSize) {
    final layout = slot.layout;
    if (layout == null) return Offset.zero & regionSize;
    final sheets = layout.sheets;
    if (sheets.isEmpty) return null;
    return switch (side) {
      _Side.left || _Side.single => sheets.first,
      _Side.right => sheets.length > 1 ? sheets[1] : null,
    };
  }

  /// Ink check on a tiny proxy: blank paper, error boxes and scrims are
  /// evicted (the next turn recaptures or slides).
  Future<void> _validate(String key, _Snapshot snapshot) async {
    final ink =
        await snapshotProxyInk(snapshot.image, paper: widget.paperColor);
    if (!mounted || _cache[key] != snapshot) return;
    if (pageSnapshotInkIsValid(ink)) {
      snapshot.validated = true;
      return;
    }
    logPageCurl(
        'snapshot $key rejected (ink ${(ink * 100).toStringAsFixed(1)}%)');
    _cache.remove(key);
    if (_turn?.front == snapshot.image || _turn?.back == snapshot.image) {
      _turnToSlide('snapshot $key rejected');
    }
    snapshot.image.dispose();
  }

  void _schedulePrewarm() {
    _prewarmTimer?.cancel();
    if (widget.style != MushafTurnStyle.curl) return;
    _prewarmTimer = Timer(kMushafTurnPrewarmDelay, _prewarm);
  }

  void _prewarm() {
    if (!mounted || _turn != null || _anim.isAnimating) return;
    _stats.mark('prewarm');
    for (final key in _neededFor(_index)) {
      final parts = key.split(':');
      _snapshot(int.parse(parts[0]), _Side.values.byName(parts[1]));
    }
    _trimCache();
    _prebuildTimer?.cancel();
    _prebuildTimer = Timer(kMushafTurnPrebuildDelay, _prebuild);
  }

  /// Real idle: build one more page ahead (then behind), so a later burst of
  /// turns finds its pages built and painted. One per beat, and never while
  /// the reader is turning, so a page build never lands next to a turn.
  void _prebuild() {
    if (!mounted || _turn != null || _anim.isAnimating) return;
    for (final next in [_index + 2, _index - 2]) {
      if (_inBounds(next) && !_window.contains(next)) {
        setState(() => _window.add(next));
        _schedulePrewarm();
        return;
      }
    }
  }

  // -------------------------------------------------------------- turns

  Rect? _regionRect(int index) {
    final boundary = _slots[index]?.boundary;
    final stage = context.findRenderObject() as RenderBox?;
    if (boundary == null || stage == null || !stage.hasSize) return null;
    final origin = boundary.localToGlobal(Offset.zero, ancestor: stage);
    return origin & boundary.size;
  }

  PageCurlLeaf? _leafFor(MushafTurnSlot slot, Size regionSize) {
    final layout = slot.layout;
    if (layout == null) {
      return PageCurlLeaf.single(Offset.zero & regionSize);
    }
    final sheets = layout.sheets;
    if (widget.spread && sheets.length == 2) {
      return PageCurlLeaf.spread(
          left: sheets[0], right: sheets[1], forward: true);
    }
    return sheets.isEmpty ? null : PageCurlLeaf.single(sheets.first);
  }

  /// Starts a turn from the current item towards [direction] (+1/-1).
  /// Returns null at a bound (nothing moves).
  _Turn? _beginTurn(int direction) {
    final target = _index + direction;
    if (!_inBounds(target)) return null;
    _prebuildTimer?.cancel();
    final a = direction > 0 ? _index : target;
    // The item after the target joins the window now, so a chained turn
    // finds it built and painted.
    final beyond = target + direction;
    if (_inBounds(beyond) && _window.add(beyond)) setState(() {});
    final topIsA = direction > 0;
    final region = _regionRect(_index);
    if (region == null) {
      return _slideTurn(a, topIsA, Offset.zero & context.size!, 'no region');
    }
    String? reason;
    PageCurlLeaf? leaf;
    ui.Image? front;
    ui.Image? back;
    if (widget.style != MushafTurnStyle.curl) {
      reason = 'style';
    } else if (_shader == null) {
      reason = _shaderFailed ? 'shader failed' : 'shader not loaded';
    } else {
      try {
        leaf = _leafFor(_slot(_index), region.size);
        front = _snapshot(a, _frontSide);
        back = _snapshot(a + 1, _backSide);
        if (leaf == null) reason = 'no sheet layout';
        if (front == null) reason = 'front p${a}L not painted';
        if (back == null) reason = 'back ${a + 1}R not painted';
      } catch (error) {
        reason = 'exception: $error';
      }
    }
    if (reason != null) return _slideTurn(a, topIsA, region, reason);
    final turn = _Turn(
      a: a,
      topIsA: topIsA,
      region: region,
      stageWidth: context.size!.width,
      leaf: leaf,
      front: front,
      back: back,
    );
    turn.grab = turn.rest;
    turn.finger = topIsA ? turn.rest : turn.landing;
    _stats.begin(MediaQuery.maybeOf(context));
    _stats.mark('begin');
    setState(() => _turn = turn);
    return turn;
  }

  _Turn _slideTurn(int a, bool topIsA, Rect region, String reason) {
    logPageCurl('turn $a->${a + 1} slides: $reason');
    _stats.recordFallback();
    final turn = _Turn(
      a: a,
      topIsA: topIsA,
      region: region,
      stageWidth: context.size!.width,
    )..slide = topIsA ? 0 : 1;
    _stats.begin(MediaQuery.maybeOf(context));
    _stats.mark('begin');
    setState(() => _turn = turn);
    return turn;
  }

  void _turnToSlide(String reason) {
    final turn = _turn;
    if (turn == null || !turn.curl) return;
    final progress = turn.progress;
    _anim.stop();
    logPageCurl('turn switched to slide: $reason');
    _stats.recordFallback();
    setState(() {
      _turn = _Turn(
        a: turn.a,
        topIsA: turn.topIsA,
        region: turn.region,
        stageWidth: turn.stageWidth,
      )..slide = progress;
    });
    _animateTurnTo(progress >= 0.5);
  }

  /// Animates the active turn to settle on b ([toB]) or a.
  void _animateTurnTo(bool toB, {Duration? duration}) {
    final turn = _turn!;
    turn.targetB = toB;
    if (turn.curl) {
      final from = turn.finger;
      final to = toB ? turn.landing : turn.rest;
      _fingerAt = (t) => Offset.lerp(from, to, Curves.easeOut.transform(t))!;
      _slideAt = null;
      final remaining = (turn.progress - (toB ? 1 : 0)).abs();
      _runAnim(duration ?? _scaled(remaining));
    } else {
      final from = turn.slide;
      final to = toB ? 1.0 : 0.0;
      _slideAt = (t) => from + (to - from) * Curves.easeOut.transform(t);
      _fingerAt = null;
      _runAnim(duration ?? _scaled((to - from).abs()));
    }
  }

  /// Non-interactive turn (tap, audio, chain): the finger follows the
  /// hand-turn path from where the leaf is to where it must land.
  void _autoTurn(int direction) {
    final turn = _beginTurn(direction);
    if (turn == null) return;
    if (!turn.curl) {
      _animateTurnTo(direction > 0);
      return;
    }
    final leaf = turn.leaf!;
    turn.grab = pageCurlAutoGrab(leaf);
    final start = direction > 0 ? 0.0 : 1.0;
    final end = 1.0 - start;
    turn.finger = pageCurlAutoFinger(leaf, start);
    turn.targetB = direction > 0;
    _fingerAt = (t) => pageCurlAutoFinger(
          leaf,
          start + (end - start) * Curves.easeInOut.transform(t),
        );
    _slideAt = null;
    _runAnim(kMushafTurnDuration);
  }

  Duration _scaled(double fraction) => Duration(
        milliseconds:
            (kMushafTurnDuration.inMilliseconds * fraction.clamp(0.35, 1.0))
                .round(),
      );

  void _runAnim(Duration duration) {
    _anim
      ..duration = duration
      ..forward(from: 0);
  }

  void _onAnimTick() {
    _stats.mark('anim');
    final turn = _turn;
    if (turn == null) return;
    final t = _anim.value;
    if (_fingerAt != null) turn.finger = _fingerAt!(t);
    if (_slideAt != null) turn.slide = _slideAt!(t);
    _tick.value++;
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final turn = _turn;
    if (turn == null || turn.targetB == null) return;
    _settle(turn.targetB! ? turn.b : turn.a);
  }

  /// Finishes the animating turn quickly, then runs one queued turn.
  void _chain(int direction) {
    _pending = direction;
    if (!_anim.isAnimating) return;
    final left = (1 - _anim.value) * _anim.duration!.inMicroseconds;
    final finish = Duration(
      microseconds:
          math.min(left.round(), kMushafTurnChainFinish.inMicroseconds),
    );
    _anim.animateTo(1, duration: finish, curve: Curves.linear);
  }

  void _settle(int index) {
    _stats.mark('settle');
    final changed = index != _index;
    final programmatic = _programmatic;
    _programmatic = false;
    _fingerAt = null;
    _slideAt = null;
    setState(() {
      _turn = null;
      _index = index;
      _resetWindow();
    });
    _stats.end();
    if (changed) widget.onIndexChanged(index, programmatic: programmatic);
    final pending = _pending;
    _pending = null;
    _trimCache();
    if (pending != null && mounted) {
      _autoTurn(pending);
      return;
    }
    _schedulePrewarm();
  }

  void _cancelTurn(String reason) {
    if (_turn == null && !_anim.isAnimating) return;
    logPageCurl('turn cancelled: $reason');
    _anim.stop();
    _pending = null;
    _fingerAt = null;
    _slideAt = null;
    setState(() {
      _turn = null;
      _resetWindow();
    });
    _stats.end();
  }

  // ------------------------------------------------------ programmatic

  void _animateTo(int index) {
    if (!_inBounds(index) || index == _index) return;
    final direction = index - _index;
    if (direction.abs() != 1 || widget.style == MushafTurnStyle.none) {
      _jumpTo(index, programmatic: true);
      return;
    }
    if (_turn != null) {
      _chain(direction);
      return;
    }
    _programmatic = true;
    _autoTurn(direction);
  }

  void _jumpTo(int index, {bool programmatic = true}) {
    if (!_inBounds(index) || index == _index) return;
    _anim.stop();
    _pending = null;
    setState(() {
      _turn = null;
      _index = index;
      _resetWindow();
    });
    widget.onIndexChanged(index, programmatic: programmatic);
    _schedulePrewarm();
  }

  // ------------------------------------------------------------ input

  bool _handleEdgeTap(MushafTurnSlot slot, Offset globalPosition) {
    final region = _regionRect(slot.index);
    final stage = context.findRenderObject() as RenderBox?;
    if (region == null || stage == null) return false;
    final local = stage.globalToLocal(globalPosition);
    final zone = region.width * kMushafTurnEdgeZone;
    final int direction;
    if (local.dx <= region.left + zone) {
      direction = 1; // left edge: next page (RTL)
    } else if (local.dx >= region.right - zone) {
      direction = -1;
    } else {
      return false;
    }
    if (_turn != null) {
      if (_anim.isAnimating) _chain(direction);
      return true;
    }
    if (!_inBounds(_index + direction)) return true; // bound: no movement
    if (widget.style == MushafTurnStyle.none) {
      _jumpTo(_index + direction, programmatic: false);
    } else {
      _autoTurn(direction);
    }
    return true;
  }

  void _onDragStart(DragStartDetails details) {
    _dragStart = details.localPosition;
    _dragIgnored = false;
    _dragChained = false;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final start = _dragStart;
    if (start == null || _dragIgnored || _dragChained) return;
    var turn = _turn;
    if (turn == null || (turn.targetB != null && _anim.isAnimating)) {
      final dx = details.localPosition.dx - start.dx;
      if (dx == 0) return;
      final direction = dx > 0 ? 1 : -1;
      if (turn != null) {
        // Mid-animation: the same way finishes it and queues one more turn,
        // the other way grabs the leaf where it is.
        final towardB = direction > 0;
        if (towardB == turn.targetB) {
          _dragChained = true;
          _chain(direction);
          return;
        }
        _anim.stop();
        turn.targetB = null;
      } else {
        if (widget.style == MushafTurnStyle.none) {
          _dragIgnored = true;
          if (_inBounds(_index + direction)) {
            _jumpTo(_index + direction, programmatic: false);
          }
          return;
        }
        turn = _beginTurn(direction);
        if (turn == null) {
          _dragIgnored = true; // bound: nothing moves
          return;
        }
        if (turn.curl) {
          final local = start - turn.region.topLeft;
          final v = turn.leaf!.toLeaf(local).dy.clamp(0.0, turn.leaf!.height);
          turn.grab = Offset(turn.leaf!.freeEdge, v);
          turn.finger = turn.topIsA ? turn.grab : turn.landing;
        }
        // The leaf starts at rest (or landed); the slop already travelled
        // counts, so measure from the touch-down point.
        _dragStartFinger = turn.finger;
        _dragStartSlide = turn.slide;
        _applyDrag(turn, start, details.localPosition);
        return;
      }
      // Grabbed mid-animation: the leaf continues from where it is.
      _dragStart = details.localPosition;
      _dragStartFinger = turn.finger;
      _dragStartSlide = turn.slide;
      return;
    }
    _applyDrag(turn, start, details.localPosition);
  }

  void _applyDrag(_Turn turn, Offset start, Offset position) {
    _stats.mark('drag');
    if (turn.curl) {
      final leaf = turn.leaf!;
      final delta = leaf.toLeaf(position - turn.region.topLeft) -
          leaf.toLeaf(start - turn.region.topLeft);
      turn.finger = _dragStartFinger + delta;
    } else {
      final dx = position.dx - start.dx;
      turn.slide = (_dragStartSlide + dx / turn.stageWidth).clamp(0.0, 1.0);
    }
    _tick.value++;
  }

  void _onDragEnd(DragEndDetails details) {
    final turn = _turn;
    _dragStart = null;
    if (turn == null || _dragIgnored || _dragChained || turn.targetB != null) {
      return;
    }
    final vx = details.velocity.pixelsPerSecond.dx;
    final progress = turn.commitProgress(spread: widget.spread);
    final bool toB;
    if (vx > kMushafTurnFlingVelocity) {
      toB = true;
    } else if (vx < -kMushafTurnFlingVelocity) {
      toB = false;
    } else {
      toB = turn.topIsA
          ? progress > kMushafTurnCommit
          : progress > 1 - kMushafTurnCommit;
    }
    _animateTurnTo(toB);
  }

  void _onDragCancel() {
    final turn = _turn;
    _dragStart = null;
    if (turn != null && turn.targetB == null) _animateTurnTo(!turn.topIsA);
  }

  // ------------------------------------------------------------ build

  Widget _host(int index, {required bool visible, required bool top}) {
    final turn = _turn;
    // Hidden: clipped to nothing. During a curl the page underneath is drawn
    // ABOVE the top page, clipped to the leaf's side: only axis-aligned
    // rect clips, which the GPU applies as a scissor.
    final Rect? clip;
    if (!visible) {
      clip = Rect.zero;
    } else if (turn != null && turn.curl && !top) {
      clip = _holeOf(turn) ?? Rect.zero;
    } else {
      clip = null;
    }
    return _hostWithClip(index, visible: visible, top: top, clip: clip);
  }

  Widget _hostWithClip(
    int index, {
    required bool visible,
    required bool top,
    required Rect? clip,
  }) {
    final slot = _slot(index);
    final turn = _turn;
    // The same widget instance across stage rebuilds: starting or settling
    // a turn must not rebuild the pages.
    final item = _items[index] ??= MushafTurnScope(
      slot: slot,
      child: widget.itemBuilder(context, index),
    );
    return _TurnItemHost(
      key: ValueKey<int>(index),
      visible: visible,
      interactive: visible && (turn == null || top),
      clipper: _TurnItemClipper(clip),
      offsetOf: turn != null && !turn.curl && visible
          ? () => _slideOffset(index)
          : null,
      tick: _tick,
      child: item,
    );
  }

  Rect? _holeOf(_Turn turn) {
    final leaf = turn.leaf!;
    final r = turn.region;
    if (!widget.spread) {
      return turn.topIsA ? r : null;
    }
    final hinge = r.left + leaf.hingeX;
    return turn.topIsA
        ? Rect.fromLTRB(r.left, r.top, hinge, r.bottom)
        : Rect.fromLTRB(hinge, r.top, r.right, r.bottom);
  }

  /// RTL slide: moving to b pushes a to the right and pulls b in from the left.
  Offset _slideOffset(int index) {
    final turn = _turn!;
    final w = turn.stageWidth;
    final p = turn.slide;
    return index == turn.a ? Offset(p * w, 0) : Offset(-(1 - p) * w, 0);
  }

  @override
  Widget build(BuildContext context) {
    final turn = _turn;
    final shown = turn == null ? {_index} : {turn.a, turn.b};
    final top = turn == null ? _index : (turn.topIsA ? turn.a : turn.b);
    final under = shown.where((i) => i != top);
    final curl = turn != null && turn.curl;
    final order = [
      for (final i in _window)
        if (!shown.contains(i)) i,
      if (!curl) ...under,
      top,
      // Curl: the revealed page goes over the top one, clipped to its half.
      if (curl) ...under,
    ];
    _slots.removeWhere((i, _) => !order.contains(i));
    _items.removeWhere((i, _) => !order.contains(i));
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(
            debugOwner: this,
            supportedDevices: null,
          ),
          (r) => r
            ..dragStartBehavior = DragStartBehavior.down
            ..onStart = _onDragStart
            ..onUpdate = _onDragUpdate
            ..onEnd = _onDragEnd
            ..onCancel = _onDragCancel,
        ),
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final i in order)
            _host(i, visible: shown.contains(i), top: i == top),
          if (turn != null && turn.curl)
            Positioned.fromRect(
              rect: turn.region,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _LeafPainter(
                      shader: _shader!,
                      turn: turn,
                      dark: Theme.of(context).brightness == Brightness.dark,
                      repaint: _tick,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Keeps a pager item mounted but invisible and inert while hidden.
class _TurnItemHost extends StatelessWidget {
  const _TurnItemHost({
    super.key,
    required this.visible,
    required this.interactive,
    required this.clipper,
    required this.offsetOf,
    required this.tick,
    required this.child,
  });

  final bool visible;
  final bool interactive;
  final _TurnItemClipper clipper;
  final Offset Function()? offsetOf;
  final ValueListenable<int> tick;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offsetOf = this.offsetOf;
    return TickerMode(
      enabled: visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: IgnorePointer(
          ignoring: !interactive,
          child: ClipRect(
            clipper: clipper,
            child: offsetOf == null
                ? child
                : ValueListenableBuilder<int>(
                    valueListenable: tick,
                    child: child,
                    builder: (context, _, child) => Transform.translate(
                      offset: offsetOf(),
                      child: child,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Full item (null), nothing (hidden) or the leaf's half of the region.
class _TurnItemClipper extends CustomClipper<Rect> {
  _TurnItemClipper(this.clip);

  final Rect? clip;

  @override
  Rect getClip(Size size) => clip ?? Offset.zero & size;

  @override
  bool shouldReclip(_TurnItemClipper oldClipper) => oldClipper.clip != clip;
}

class _LeafPainter extends CustomPainter {
  _LeafPainter({
    required this.shader,
    required this.turn,
    required this.dark,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final ui.FragmentShader shader;
  final _Turn turn;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final leaf = turn.leaf!;
    PageCurlPainter(
      shader: shader,
      leaf: leaf,
      frame: computePageCurl(leaf: leaf, grab: turn.grab, finger: turn.finger),
      front: turn.front!,
      back: turn.back!,
      dark: dark,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_LeafPainter oldDelegate) =>
      oldDelegate.turn != turn || oldDelegate.dark != dark;
}
