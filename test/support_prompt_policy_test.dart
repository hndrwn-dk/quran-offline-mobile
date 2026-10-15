import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/support/reading_milestone.dart';
import 'package:quran_offline/core/support/support_prompt_policy.dart';

void main() {
  final t0 = DateTime(2026, 6, 1, 8);

  SupportPromptPolicy policyAt(DateTime now) {
    return SupportPromptPolicy(clock: () => now);
  }

  ReadingMilestone juz(int number, {int completed = 1}) {
    return ReadingMilestone(
      kind: ReadingMilestoneKind.juz,
      completedJuz: completed,
      juzNumber: number,
    );
  }

  const ten = ReadingMilestone(
    kind: ReadingMilestoneKind.ten,
    completedJuz: 10,
  );

  const khatam = ReadingMilestone(
    kind: ReadingMilestoneKind.khatam,
    completedJuz: 30,
  );

  group('SupportPromptPolicy ask window', () {
    test('ask is allowed when the user has never been asked or purchased', () {
      final policy = policyAt(t0);
      expect(policy.askAllowed(), isTrue);
    });

    test('ask waits 30 days after the last ask', () {
      final asked = t0.subtract(const Duration(days: 29));
      expect(
        policyAt(t0).askAllowed(lastAskAt: asked),
        isFalse,
      );
      expect(
        policyAt(asked.add(const Duration(days: 30))).askAllowed(lastAskAt: asked),
        isTrue,
      );
    });

    test('ask waits 90 days after a purchase', () {
      final bought = t0.subtract(const Duration(days: 89));
      expect(
        policyAt(t0).askAllowed(lastPurchaseAt: bought),
        isFalse,
      );
      expect(
        policyAt(bought.add(const Duration(days: 90))).askAllowed(lastPurchaseAt: bought),
        isTrue,
      );
    });

    test('a recent purchase blocks an ask even when the last ask is old', () {
      expect(
        policyAt(t0).askAllowed(
          lastAskAt: t0.subtract(const Duration(days: 40)),
          lastPurchaseAt: t0.subtract(const Duration(days: 10)),
        ),
        isFalse,
      );
    });
  });

  group('SupportPromptPolicy milestones', () {
    test('a single juz celebration never asks', () {
      final policy = policyAt(t0);
      final step = policy.present(
        current: null,
        shown: const {},
        cycle: 1,
        milestone: juz(4, completed: 4),
        milestoneCycle: 1,
      );
      expect(step.card, isNotNull);
      expect(step.card!.askVisible, isFalse);
      expect(step.card!.milestone.kind, ReadingMilestoneKind.juz);
    });

    test('ten juz and khatam ask only when the window allows it', () {
      final open = policyAt(t0).present(
        current: null,
        shown: const {},
        cycle: 1,
        milestone: ten,
        milestoneCycle: 1,
      );
      expect(open.card!.askVisible, isTrue);

      final blocked = policyAt(t0).present(
        current: null,
        shown: const {},
        cycle: 1,
        milestone: khatam,
        milestoneCycle: 1,
        lastPurchaseAt: t0.subtract(const Duration(days: 3)),
      );
      expect(blocked.card!.milestone.kind, ReadingMilestoneKind.khatam);
      expect(blocked.card!.askVisible, isFalse);
    });

    test('each milestone is shown once per cycle', () {
      final policy = policyAt(t0);
      final first = policy.present(
        current: null,
        shown: const {},
        cycle: 1,
        milestone: ten,
        milestoneCycle: 1,
      );
      final dismissed = policy.dismiss(first);
      final again = policyAt(t0.add(const Duration(days: 31))).present(
        current: dismissed.card,
        shown: dismissed.shown,
        cycle: 1,
        milestone: ten,
        milestoneCycle: 1,
        lastAskAt: dismissed.lastAskAt,
      );
      expect(again.card, isNull);
    });

    test('an open card stays until dismiss or 3 days', () {
      final policy = policyAt(t0);
      final opened = policy.present(
        current: null,
        shown: const {},
        cycle: 1,
        milestone: ten,
        milestoneCycle: 1,
      );
      final still = policyAt(t0.add(const Duration(days: 2, hours: 23))).present(
        current: opened.card,
        shown: opened.shown,
        cycle: 1,
      );
      expect(still.card, isNotNull);

      final expired = policyAt(t0.add(const Duration(days: 3))).present(
        current: opened.card,
        shown: opened.shown,
        cycle: 1,
      );
      expect(expired.card, isNull);
      expect(expired.shown, contains('1:ten'));
      expect(expired.lastAskAt, isNull);
    });

    test('Tutup records lastAskAt only when the ask was visible', () {
      final withAsk = policyAt(t0).present(
        current: null,
        shown: const {},
        cycle: 1,
        milestone: ten,
        milestoneCycle: 1,
      );
      final asked = policyAt(t0).dismiss(withAsk);
      expect(asked.lastAskAt, t0);
      expect(asked.card, isNull);

      final quiet = policyAt(t0).present(
        current: null,
        shown: const {},
        cycle: 1,
        milestone: juz(2, completed: 2),
        milestoneCycle: 1,
      );
      final closed = policyAt(t0).dismiss(quiet);
      expect(closed.lastAskAt, isNull);
    });

    test('a visible card is not replaced by the next milestone', () {
      final policy = policyAt(t0);
      final opened = policy.present(
        current: null,
        shown: const {},
        cycle: 1,
        milestone: juz(3, completed: 3),
        milestoneCycle: 1,
      );
      final kept = policy.present(
        current: opened.card,
        shown: opened.shown,
        cycle: 1,
        milestone: ten,
        milestoneCycle: 1,
      );
      expect(kept.card!.milestone.kind, ReadingMilestoneKind.juz);
      expect(kept.shown, isNot(contains('1:ten')));
    });
  });
}
