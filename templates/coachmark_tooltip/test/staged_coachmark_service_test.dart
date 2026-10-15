import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// After copying template lib/ into your app, fix import paths below.
// Example: import 'package:your_app/core/coachmark/staged_coachmark_service.dart';

import '../lib/coachmark_storage_keys.dart';
import '../lib/staged_coachmark_service.dart';

void main() {
  const config = CoachmarkConfig(
    keys: CoachmarkStorageKeys(prefix: 'test_coachmark'),
    firstShowMinAppOpens: 3,
    maxShowCount: 3,
    reminderDelays: [
      Duration(days: 7),
      Duration(days: 14),
    ],
  );

  final t0 = DateTime(2026, 1, 1, 12);

  group('StagedCoachmarkService.shouldShowCoachmark', () {
    test('stops when CTA was tapped', () {
      expect(
        StagedCoachmarkService.shouldShowCoachmark(
          config: config,
          hasTappedCta: true,
          showCount: 0,
          appOpenCount: 10,
          lastShownAtMs: null,
          now: t0,
        ),
        isFalse,
      );
    });

    test('stops at max show count', () {
      expect(
        StagedCoachmarkService.shouldShowCoachmark(
          config: config,
          hasTappedCta: false,
          showCount: 3,
          appOpenCount: 10,
          lastShownAtMs: t0.millisecondsSinceEpoch,
          now: t0.add(const Duration(days: 30)),
        ),
        isFalse,
      );
    });

    test('first show needs min app opens', () {
      expect(
        StagedCoachmarkService.shouldShowCoachmark(
          config: config,
          hasTappedCta: false,
          showCount: 0,
          appOpenCount: 2,
          lastShownAtMs: null,
          now: t0,
        ),
        isFalse,
      );
      expect(
        StagedCoachmarkService.shouldShowCoachmark(
          config: config,
          hasTappedCta: false,
          showCount: 0,
          appOpenCount: 3,
          lastShownAtMs: null,
          now: t0,
        ),
        isTrue,
      );
    });

    test('second show needs 7 days', () {
      final last = t0.millisecondsSinceEpoch;
      expect(
        StagedCoachmarkService.shouldShowCoachmark(
          config: config,
          hasTappedCta: false,
          showCount: 1,
          appOpenCount: 5,
          lastShownAtMs: last,
          now: t0.add(const Duration(days: 6)),
        ),
        isFalse,
      );
      expect(
        StagedCoachmarkService.shouldShowCoachmark(
          config: config,
          hasTappedCta: false,
          showCount: 1,
          appOpenCount: 5,
          lastShownAtMs: last,
          now: t0.add(const Duration(days: 7)),
        ),
        isTrue,
      );
    });

    test('third show needs 14 days', () {
      final last = t0.millisecondsSinceEpoch;
      expect(
        StagedCoachmarkService.shouldShowCoachmark(
          config: config,
          hasTappedCta: false,
          showCount: 2,
          appOpenCount: 5,
          lastShownAtMs: last,
          now: t0.add(const Duration(days: 13)),
        ),
        isFalse,
      );
      expect(
        StagedCoachmarkService.shouldShowCoachmark(
          config: config,
          hasTappedCta: false,
          showCount: 2,
          appOpenCount: 5,
          lastShownAtMs: last,
          now: t0.add(const Duration(days: 14)),
        ),
        isTrue,
      );
    });
  });

  group('StagedCoachmarkService persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('recordShown then recordCtaTapped stops reminders', () async {
      final service = StagedCoachmarkService(
        config: config,
        now: () => t0,
      );
      await service.recordShown();
      await service.recordCtaTapped();

      final later = StagedCoachmarkService(
        config: config,
        now: () => t0.add(const Duration(days: 365)),
      );
      expect(await later.shouldShow(), isFalse);
    });
  });
}
