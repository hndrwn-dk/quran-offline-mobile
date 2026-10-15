import 'package:quran_offline/core/support/reading_milestone.dart';

class ActiveReadingCard {
  const ActiveReadingCard({
    required this.milestone,
    required this.cycle,
    required this.shownAt,
    required this.askVisible,
  });

  final ReadingMilestone milestone;
  final int cycle;
  final DateTime shownAt;
  final bool askVisible;

  String get storageId => '$cycle:${milestone.id}';
}

class PromptStep {
  const PromptStep({
    required this.card,
    required this.shown,
    required this.lastAskAt,
  });

  final ActiveReadingCard? card;
  final Set<String> shown;
  final DateTime? lastAskAt;
}

/// When a Beranda celebration may ask for support. Clock is injectable.
class SupportPromptPolicy {
  SupportPromptPolicy({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const askGap = Duration(days: 30);
  static const purchaseGap = Duration(days: 90);
  static const cardLifetime = Duration(days: 3);

  final DateTime Function() _clock;

  DateTime get now => _clock();

  bool askAllowed({DateTime? lastAskAt, DateTime? lastPurchaseAt}) {
    if (lastPurchaseAt != null && now.difference(lastPurchaseAt) < purchaseGap) {
      return false;
    }
    if (lastAskAt != null && now.difference(lastAskAt) < askGap) {
      return false;
    }
    return true;
  }

  bool isExpired(ActiveReadingCard card) {
    return now.difference(card.shownAt) >= cardLifetime;
  }

  PromptStep present({
    required ActiveReadingCard? current,
    required Set<String> shown,
    required int cycle,
    ReadingMilestone? milestone,
    int? milestoneCycle,
    DateTime? lastAskAt,
    DateTime? lastPurchaseAt,
  }) {
    if (current != null && isExpired(current)) {
      return present(
        current: null,
        shown: {...shown, current.storageId},
        cycle: cycle,
        milestone: milestone,
        milestoneCycle: milestoneCycle,
        lastAskAt: lastAskAt,
        lastPurchaseAt: lastPurchaseAt,
      );
    }
    if (current != null) {
      return PromptStep(card: current, shown: shown, lastAskAt: lastAskAt);
    }
    if (milestone == null) {
      return PromptStep(card: null, shown: shown, lastAskAt: lastAskAt);
    }
    final ownerCycle = milestoneCycle ?? cycle;
    final storageId = '$ownerCycle:${milestone.id}';
    if (shown.contains(storageId)) {
      return PromptStep(card: null, shown: shown, lastAskAt: lastAskAt);
    }
    final ask = milestone.kind != ReadingMilestoneKind.juz &&
        askAllowed(lastAskAt: lastAskAt, lastPurchaseAt: lastPurchaseAt);
    final card = ActiveReadingCard(
      milestone: milestone,
      cycle: ownerCycle,
      shownAt: now,
      askVisible: ask,
    );
    return PromptStep(
      card: card,
      shown: {...shown, storageId},
      lastAskAt: lastAskAt,
    );
  }

  PromptStep dismiss(PromptStep step) {
    final card = step.card;
    if (card == null) return step;
    return PromptStep(
      card: null,
      shown: {...step.shown, card.storageId},
      lastAskAt: card.askVisible ? now : step.lastAskAt,
    );
  }
}
