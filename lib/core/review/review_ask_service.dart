import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/review/review_ask_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a Play review at most once, at a completion moment.
final reviewAskServiceProvider = Provider<ReviewAskService>((ref) {
  return ReviewAskService(ref);
});

class ReviewAskService {
  ReviewAskService(this._ref);

  final Ref _ref;
  Future<ReviewAskController>? _controller;
  bool _inFlight = false;

  Future<ReviewAskController> _ensureController() {
    return _controller ??= SharedPreferences.getInstance().then(
      (prefs) => ReviewAskController(
        prefs: prefs,
        requestReview: () => InAppReview.instance.requestReview(),
      ),
    );
  }

  /// Called only by the dwell-gated completion signal.
  Future<void> onUnitCompleted() => _ask();

  bool _audioPlaying() => _ref.read(audioPlayerProvider).isPlaying;

  Future<void> _ask() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final controller = await _ensureController();
      if (controller.hasRequested) return;
      await controller.onCompletion(isAudioPlaying: _audioPlaying);
    } catch (_) {
      // Silent by design.
    } finally {
      _inFlight = false;
    }
  }
}
