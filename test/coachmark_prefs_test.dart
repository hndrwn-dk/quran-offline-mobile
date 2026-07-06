import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/coachmark/support_coachmark_service.dart';
import 'package:quran_offline/core/utils/coachmark_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  group('SupportCoachmarkService.shouldShowCoachmark', () {
    test('returns false when CTA was tapped', () {
      expect(
        SupportCoachmarkService.shouldShowCoachmark(
          hasTappedSupportCta: true,
          coachmarkShowCount: 0,
          appOpenCount: 10,
          lastCoachmarkShownAtMs: null,
          now: t0,
        ),
        isFalse,
      );
    });

    test('returns false when show count reached max', () {
      expect(
        SupportCoachmarkService.shouldShowCoachmark(
          hasTappedSupportCta: false,
          coachmarkShowCount: 3,
          appOpenCount: 10,
          lastCoachmarkShownAtMs: t0.millisecondsSinceEpoch,
          now: t0.add(const Duration(days: 30)),
        ),
        isFalse,
      );
    });

    test('first show requires app open count threshold', () {
      expect(
        SupportCoachmarkService.shouldShowCoachmark(
          hasTappedSupportCta: false,
          coachmarkShowCount: 0,
          appOpenCount: 2,
          lastCoachmarkShownAtMs: null,
          now: t0,
        ),
        isFalse,
      );
      expect(
        SupportCoachmarkService.shouldShowCoachmark(
          hasTappedSupportCta: false,
          coachmarkShowCount: 0,
          appOpenCount: 3,
          lastCoachmarkShownAtMs: null,
          now: t0,
        ),
        isTrue,
      );
    });

    test('second show requires 7 days since last shown', () {
      final lastShown = t0.millisecondsSinceEpoch;
      expect(
        SupportCoachmarkService.shouldShowCoachmark(
          hasTappedSupportCta: false,
          coachmarkShowCount: 1,
          appOpenCount: 5,
          lastCoachmarkShownAtMs: lastShown,
          now: t0.add(const Duration(days: 6)),
        ),
        isFalse,
      );
      expect(
        SupportCoachmarkService.shouldShowCoachmark(
          hasTappedSupportCta: false,
          coachmarkShowCount: 1,
          appOpenCount: 5,
          lastCoachmarkShownAtMs: lastShown,
          now: t0.add(const Duration(days: 7)),
        ),
        isTrue,
      );
    });

    test('third show requires 14 days since last shown', () {
      final lastShown = t0.millisecondsSinceEpoch;
      expect(
        SupportCoachmarkService.shouldShowCoachmark(
          hasTappedSupportCta: false,
          coachmarkShowCount: 2,
          appOpenCount: 5,
          lastCoachmarkShownAtMs: lastShown,
          now: t0.add(const Duration(days: 13)),
        ),
        isFalse,
      );
      expect(
        SupportCoachmarkService.shouldShowCoachmark(
          hasTappedSupportCta: false,
          coachmarkShowCount: 2,
          appOpenCount: 5,
          lastCoachmarkShownAtMs: lastShown,
          now: t0.add(const Duration(days: 14)),
        ),
        isTrue,
      );
    });

    test('late return after weeks still shows when threshold met', () {
      final lastShown = t0.millisecondsSinceEpoch;
      expect(
        SupportCoachmarkService.shouldShowCoachmark(
          hasTappedSupportCta: false,
          coachmarkShowCount: 1,
          appOpenCount: 5,
          lastCoachmarkShownAtMs: lastShown,
          now: t0.add(const Duration(days: 45)),
        ),
        isTrue,
      );
    });
  });

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

  group('SupportCoachmarkService persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('recordShown increments count and stores timestamp', () async {
      final service = SupportCoachmarkService(now: () => t0);

      await service.recordShown();
      expect(await service.shouldShow(), isFalse);

      final serviceLater = SupportCoachmarkService(
        now: () => t0.add(const Duration(days: 7)),
      );
      expect(await serviceLater.shouldShow(), isTrue);
    });

    test('recordCtaTapped stops all future reminders', () async {
      final service = SupportCoachmarkService(now: () => t0);
      await service.recordShown();
      await service.recordCtaTapped();

      final serviceLater = SupportCoachmarkService(
        now: () => t0.add(const Duration(days: 365)),
      );
      expect(await serviceLater.shouldShow(), isFalse);
    });

    test('migrates legacy has_seen_support_coachmark to max show count', () async {
      SharedPreferences.setMockInitialValues({
        SupportCoachmarkKeys.legacySeenKey: true,
      });

      final service = SupportCoachmarkService(now: () => t0);
      expect(await service.shouldShow(), isFalse);
      expect(
        SharedPreferences.getInstance().then(
          (p) => p.containsKey(SupportCoachmarkKeys.legacySeenKey),
        ),
        completion(isFalse),
      );
    });
  });
}
