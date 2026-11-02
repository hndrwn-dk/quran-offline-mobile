import 'dart:async';
import 'dart:ui' as ui;

import 'dart:developer' show Timeline;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Frame, capture and memory numbers for page turns (debug and profile only).
///
/// A session starts with the first turn and ends 1.5 s after the last one
/// settles; its summary is logged as one `[MushafTurnStats]` line, so a test
/// scenario (e.g. ten rapid turns) reads as one entry in `adb logcat`.
class PageTurnStats {
  static const _idle = Duration(milliseconds: 1500);

  final List<ui.FrameTiming> _frames = [];
  final List<int> _captureMicros = [];
  int _turns = 0;
  int _fallbacks = 0;
  int _peakBytes = 0;
  int _lastBytes = 0;
  int _active = 0;
  bool _listening = false;
  bool _inSession = false;
  Timer? _idleTimer;
  double _refreshRate = 60;

  /// (monotonic µs, phase) marks, to name the phase of each slow frame.
  final List<(int, String)> _phases = [];

  /// Notes what the stage is doing from now on (begin, drag, anim, ...).
  void mark(String phase) {
    if (!_enabled || !_inSession) return;
    if (_phases.isNotEmpty && _phases.last.$2 == phase) return;
    _phases.add((Timeline.now, phase));
  }

  String _phaseAt(int micros) {
    var phase = 'idle';
    for (final (at, name) in _phases) {
      if (at > micros) break;
      phase = name;
    }
    return phase;
  }

  bool get _enabled => !kReleaseMode;

  void begin(MediaQueryData? media) {
    if (!_enabled) return;
    _active++;
    _turns++;
    _idleTimer?.cancel();
    if (!_inSession) {
      _inSession = true;
      _frames.clear();
      _captureMicros.clear();
      _turns = 1;
      _fallbacks = 0;
      _phases.clear();
      _peakBytes = _lastBytes;
      final displays = WidgetsBinding.instance.platformDispatcher.displays;
      if (displays.isNotEmpty) _refreshRate = displays.first.refreshRate;
    }
    if (!_listening) {
      _listening = true;
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    }
  }

  void end() {
    if (!_enabled || _active == 0) return;
    _active--;
    if (_active > 0) return;
    _idleTimer?.cancel();
    _idleTimer = Timer(_idle, _report);
  }

  void recordCapture(int micros) {
    if (_enabled) _captureMicros.add(micros);
  }

  void recordFallback() {
    if (_enabled) _fallbacks++;
  }

  void recordCache(int bytes) {
    _lastBytes = bytes;
    if (bytes > _peakBytes) _peakBytes = bytes;
  }

  void _onTimings(List<ui.FrameTiming> timings) {
    if (_inSession) _frames.addAll(timings);
  }

  void _report() {
    if (!_inSession) return;
    _inSession = false;
    final budget = 1000000 / _refreshRate;
    final build = [for (final f in _frames) f.buildDuration.inMicroseconds];
    final raster = [for (final f in _frames) f.rasterDuration.inMicroseconds];
    final slow = _frames
        .where((f) =>
            f.buildDuration.inMicroseconds > budget ||
            f.rasterDuration.inMicroseconds > budget)
        .toList();
    // Slow frames while nothing moves (idle prewarm/prebuild after a turn
    // settled) are not visible as stutter; they are reported apart.
    String phaseOf(ui.FrameTiming f) =>
        _phaseAt(f.timestampInMicroseconds(ui.FramePhase.vsyncStart));
    const moving = {'begin', 'drag', 'anim', 'settle'};
    final jank = slow.where((f) => moving.contains(phaseOf(f))).length;
    final idleSlow = slow.length - jank;
    for (final f in slow) {
      debugPrint(
        '[MushafTurnJank] phase=${phaseOf(f)} '
        'ui=${(f.buildDuration.inMicroseconds / 1000).toStringAsFixed(1)} '
        'raster=${(f.rasterDuration.inMicroseconds / 1000).toStringAsFixed(1)}',
      );
    }
    debugPrint(
      '[MushafTurnStats] turns=$_turns frames=${_frames.length} '
      'hz=${_refreshRate.round()} '
      'ui(p50/p90/max ms)=${_pct(build)} raster=${_pct(raster)} '
      'jank=$jank idleSlow=$idleSlow fallbacks=$_fallbacks '
      'captures=${_captureMicros.length} capture(p50/p90 ms)=${_pct(_captureMicros, two: true)} '
      'cache(peak/now MB)=${_mb(_peakBytes)}/${_mb(_lastBytes)}',
    );
  }

  static String _mb(int bytes) => (bytes / 1048576).toStringAsFixed(1);

  static String _pct(List<int> micros, {bool two = false}) {
    if (micros.isEmpty) return '-';
    final sorted = [...micros]..sort();
    String at(double q) =>
        (sorted[((sorted.length - 1) * q).round()] / 1000).toStringAsFixed(1);
    final max = (sorted.last / 1000).toStringAsFixed(1);
    return two ? '${at(0.5)}/${at(0.9)}' : '${at(0.5)}/${at(0.9)}/$max';
  }

  void dispose() {
    _idleTimer?.cancel();
    if (_listening) SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }
}

/// Opt-in (`--dart-define=QO_FRAME_LOG=true`, profile builds): logs every
/// slow frame of the Mushaf reader, whatever pager is active, for baselines.
class MushafFrameLog {
  static bool _started = false;

  static void start() {
    if (_started || !const bool.fromEnvironment('QO_FRAME_LOG')) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback((timings) {
      final displays = WidgetsBinding.instance.platformDispatcher.displays;
      final hz = displays.isEmpty ? 60.0 : displays.first.refreshRate;
      final budget = 1000000 / hz;
      for (final f in timings) {
        final b = f.buildDuration.inMicroseconds;
        final r = f.rasterDuration.inMicroseconds;
        debugPrint(
          '[MushafFrame] ui=${(b / 1000).toStringAsFixed(1)} '
          'raster=${(r / 1000).toStringAsFixed(1)}'
          '${b > budget || r > budget ? ' SLOW' : ''}',
        );
      }
    });
  }
}
