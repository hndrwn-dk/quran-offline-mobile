import 'package:shared_preferences/shared_preferences.dart';

/// Global cold-start counter shared across all coachmark features in the app.
class AppOpenCounter {
  AppOpenCounter._();

  static const _key = 'app_open_count';

  static Future<int> increment() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_key) ?? 0) + 1;
    await prefs.setInt(_key, next);
    return next;
  }

  static Future<int> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }
}
