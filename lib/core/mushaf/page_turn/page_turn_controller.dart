import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_geometry.dart';

/// Drives one interactive (or audio-driven) Mushaf leaf turn.
///
/// The controller owns the animation value and the turn plan; the page view owns
/// the pager, the page snapshots and the "who is visible now" bookkeeping, so a
/// turn only changes the page when [onCompleted] fires (or never, when the
/// reader lets go too early).
class PageTurnController extends ChangeNotifier {
  PageTurnController({
    required TickerProvider vsync,
    Duration duration = kPageTurnDuration,
    Duration playDuration = kPageTurnPlayDuration,
  })  : _duration = duration,
        _playDuration = playDuration,
        _animation = AnimationController(vsync: vsync) {
    _animation.addListener(_onTick);
  }

  final Duration _duration;
  final Duration _playDuration;
  final AnimationController _animation;

  PageTurnPlan? _plan;
  Rect? _leftRect;
  Rect? _rightRect;
  double _hingeGap = 0;
  bool _spread = false;

  bool _dragging = false;
  bool _completing = false;

  /// Finger height inside the page, -1 (top) .. 1 (bottom), used by the curl.
  double _tilt = 0;

  /// Fired when the animation reached progress 1. The page view jumps here.
  ValueChanged<PageTurnPlan>? onCompleted;

  /// Fired when a turn ended without completing (spring back / cancel).
  VoidCallback? onCancelled;

  bool get isActive => _plan != null;
  bool get isDragging => _dragging;
  PageTurnPlan? get plan => _plan;
  double get progress => _animation.value;

  /// Fold tilt set by the finger's y at the start of the drag.
  double get tilt => _tilt;

  PageTurnGeometry? get geometry {
    final plan = _plan;
    final left = _leftRect;
    if (plan == null || left == null) return null;
    return _spread
        ? PageTurnGeometry.spread(
            leftRect: left,
            rightRect: _rightRect!,
            hingeGap: _hingeGap,
            direction: plan.direction,
            progress: progress,
          )
        : PageTurnGeometry.single(
            pageRect: left,
            direction: plan.direction,
            progress: progress,
          );
  }

  /// Stores the page areas of the spread/single page on screen.
  void setPageAreas({
    required Rect leftRect,
    required Rect rightRect,
    required double hingeGap,
    required bool spread,
  }) {
    _leftRect = leftRect;
    _rightRect = rightRect;
    _hingeGap = hingeGap;
    _spread = spread;
  }

  /// Starts an interactive turn. The caller never starts one at the book
  /// bounds: there is no page to turn to there.
  void beginDrag(PageTurnPlan plan, {double tilt = 0}) {
    _animation.stop();
    _plan = plan;
    _tilt = tilt.clamp(-1.0, 1.0);
    _dragging = true;
    _completing = false;
    _animation.value = 0;
    notifyListeners();
  }

  /// Updates an interactive drag from the *total* delta since the drag started.
  void updateDrag({
    required double totalDeltaX,
    required double pageWidth,
    double? tilt,
  }) {
    final plan = _plan;
    if (plan == null || !_dragging) return;
    if (tilt != null) _tilt = tilt.clamp(-1.0, 1.0);
    _animation.value = pageTurnDragProgress(
      deltaX: totalDeltaX,
      pageWidth: pageWidth,
      direction: plan.direction,
    );
  }

  /// Releases the drag: completes past the thresholds, springs back otherwise.
  Future<void> endDrag({required double velocityX}) async {
    final plan = _plan;
    if (plan == null || !_dragging) return;
    _dragging = false;
    final commit = pageTurnShouldCommit(
      progress: progress,
      velocityX: velocityX,
      direction: plan.direction,
    );
    await _settle(commit: commit);
  }

  /// Audio-driven turn: same leaf animation, no finger.
  Future<void> play(PageTurnPlan plan, {double tilt = 0}) async {
    _animation.stop();
    _plan = plan;
    _tilt = tilt.clamp(-1.0, 1.0);
    _dragging = false;
    _completing = false;
    _animation.value = 0;
    notifyListeners();
    await _settle(commit: true, duration: _playDuration);
  }

  Future<void> _settle({
    required bool commit,
    Duration? duration,
  }) async {
    if (_plan == null) return;
    _completing = commit;
    final remaining = commit ? 1.0 - progress : progress;
    // 400 ms ease-out on release (spec: 350-450 ms), also for the spring back.
    final span = duration ?? _duration;
    if (span.inMilliseconds <= 0 || remaining <= 0) {
      _animation.value = commit ? 1 : 0;
      _finish(completed: commit);
      return;
    }
    await _animation.animateTo(
      commit ? 1 : 0,
      duration: span,
      curve: Curves.easeOutCubic,
    );
    if (_plan == null) return; // cancelled while animating
    _finish(completed: _completing);
  }

  void _finish({required bool completed}) {
    final plan = _plan;
    if (plan == null) return;
    _plan = null;
    _dragging = false;
    _completing = false;
    notifyListeners();
    if (completed) {
      onCompleted?.call(plan);
    } else {
      onCancelled?.call();
    }
  }

  /// Aborts the turn where it is and keeps the current page.
  ///
  /// Used for fold/unfold/rotate while a turn is in flight, so the reader never
  /// lands on a page they did not finish turning to.
  void cancel() {
    if (_plan == null) return;
    _animation.stop();
    _plan = null;
    _dragging = false;
    _completing = false;
    notifyListeners();
    onCancelled?.call();
  }

  void _onTick() => notifyListeners();

  @override
  void dispose() {
    _animation.removeListener(_onTick);
    _animation.dispose();
    super.dispose();
  }
}
