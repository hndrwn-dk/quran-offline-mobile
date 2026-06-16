import 'package:shared_preferences/shared_preferences.dart';

/// Persists dismiss state for Mushaf onboarding-style hints.
class MushafHintsPrefs {
  MushafHintsPrefs._();

  static const _gestureKey = 'mushaf_gesture_hint_dismissed';
  static const _audioDismissedPrefix = 'mushaf_audio_prompt_dismissed_';

  static Future<bool> isGestureHintDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gestureKey) ?? false;
  }

  static Future<void> dismissGestureHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gestureKey, true);
  }

  static Future<bool> isAudioPromptDismissed(String reciterId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_audioDismissedPrefix$reciterId') ?? false;
  }

  static Future<void> dismissAudioPrompt(String reciterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_audioDismissedPrefix$reciterId', true);
  }
}
