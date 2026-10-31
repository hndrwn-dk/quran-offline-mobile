/// Time-based gate for "the reader actually reached the end of a unit".
///
/// Completion requires the final ayah/page to stay visible for [endDwell] and
/// the session to last at least [minimumSession]. Tests inject a fake clock.
class ReadingCompletionGate {
  ReadingCompletionGate({
    required this.minimumSession,
    this.endDwell = const Duration(seconds: 3),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration minimumSession;
  final Duration endDwell;
  final DateTime Function() _clock;

  DateTime? _sessionStart;
  DateTime? _endVisibleStart;
  bool _completed = false;

  bool get completed => _completed;

  void startSession() {
    _sessionStart = _clock();
    _endVisibleStart = null;
    _completed = false;
  }

  void setEndVisible(bool visible) {
    if (_completed) return;
    if (visible) {
      _endVisibleStart ??= _clock();
    } else {
      _endVisibleStart = null;
    }
  }

  /// Evaluates the gate; true only on the tick that completes it.
  bool tick() {
    if (_completed) return true;
    final sessionStart = _sessionStart;
    final endVisibleStart = _endVisibleStart;
    if (sessionStart == null || endVisibleStart == null) return false;

    final now = _clock();
    final sessionReady =
        now.difference(sessionStart) >= minimumSession;
    final dwellReady = now.difference(endVisibleStart) >= endDwell;
    if (sessionReady && dwellReady) {
      _completed = true;
      return true;
    }
    return false;
  }

  void dispose() {
    _sessionStart = null;
    _endVisibleStart = null;
  }
}
