/// Runs an async action at most once while in flight or after success.
///
/// Concurrent [run] callers share the same [Future]. A failed run clears the
/// latch so the next caller can retry.
class AsyncOnce {
  Future<void>? _future;

  Future<void> run(Future<void> Function() action) {
    final existing = _future;
    if (existing != null) return existing;

    late final Future<void> started;
    started = () async {
      try {
        await action();
      } catch (_) {
        if (identical(_future, started)) {
          _future = null;
        }
        rethrow;
      }
    }();
    _future = started;
    return started;
  }

  void reset() {
    _future = null;
  }
}
