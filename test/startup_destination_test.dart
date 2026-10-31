import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/startup/startup_destination.dart';

void main() {
  group('decideStartupDestination', () {
    test('stays on home when there is no last read', () {
      expect(
        decideStartupDestination(
          openToLastRead: true,
          hasLastRead: false,
          hasDeepLink: false,
        ),
        StartupDestination.home,
      );
    });

    test('resumes when a last read exists and the setting is on', () {
      expect(
        decideStartupDestination(
          openToLastRead: true,
          hasLastRead: true,
          hasDeepLink: false,
        ),
        StartupDestination.resume,
      );
    });

    test('stays on home when the setting is off', () {
      expect(
        decideStartupDestination(
          openToLastRead: false,
          hasLastRead: true,
          hasDeepLink: false,
        ),
        StartupDestination.home,
      );
    });

    test('an explicit deep link wins over auto-resume', () {
      expect(
        decideStartupDestination(
          openToLastRead: true,
          hasLastRead: true,
          hasDeepLink: true,
        ),
        StartupDestination.home,
      );
    });
  });
}
