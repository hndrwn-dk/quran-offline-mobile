import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/coachmark_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CoachmarkPrefs', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('incrementAppOpenCount increases count', () async {
      expect(await CoachmarkPrefs.getAppOpenCount(), 0);

      final first = await CoachmarkPrefs.incrementAppOpenCount();
      expect(first, 1);
      expect(await CoachmarkPrefs.getAppOpenCount(), 1);
    });
  });
}
