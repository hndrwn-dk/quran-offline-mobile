import 'package:shared_preferences/shared_preferences.dart';

/// Decides whether the one-time Play review request may run.
///
/// The flag is written after the first attempt, whether or not the Play review
/// card was shown, so the request never repeats automatically.
class ReviewAskController {
  ReviewAskController({
    required SharedPreferences prefs,
    required Future<void> Function() requestReview,
    this.delay = const Duration(milliseconds: 1500),
  })  : _prefs = prefs,
        _requestReview = requestReview;

  static const String flagKey = 'review_requested';

  final SharedPreferences _prefs;
  final Future<void> Function() _requestReview;
  final Duration delay;

  bool get hasRequested => _prefs.getBool(flagKey) ?? false;

  /// Returns true only when a review request was attempted.
  Future<bool> onCompletion({required bool Function() isAudioPlaying}) async {
    if (hasRequested || isAudioPlaying()) return false;

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    // Re-check after the delay: recitation may have started meanwhile.
    if (hasRequested || isAudioPlaying()) return false;

    try {
      await _requestReview();
    } catch (_) {
      // Silent: no Play Services, offline, or review quota reached.
    } finally {
      await _prefs.setBool(flagKey, true);
    }
    return true;
  }
}
