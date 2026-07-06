import 'package:shared_preferences/shared_preferences.dart';

/// Persists cold-start app open count (shared across coachmark contexts).
class CoachmarkPrefs {
  CoachmarkPrefs._();

  static const _appOpenCountKey = 'app_open_count';
  static const int supportCoachmarkMinOpens = 3;

  static Future<int> incrementAppOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_appOpenCountKey) ?? 0) + 1;
    await prefs.setInt(_appOpenCountKey, next);
    return next;
  }

  static Future<int> getAppOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_appOpenCountKey) ?? 0;
  }
}
