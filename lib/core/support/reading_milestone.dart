import 'package:quran_offline/core/support/khatam_coverage.dart';

enum ReadingMilestoneKind { juz, ten, twenty, khatam }

class ReadingMilestone {
  const ReadingMilestone({
    required this.kind,
    required this.completedJuz,
    this.juzNumber,
  });

  final ReadingMilestoneKind kind;
  final int completedJuz;
  final int? juzNumber;

  String get id => switch (kind) {
        ReadingMilestoneKind.juz => 'juz:$juzNumber',
        ReadingMilestoneKind.ten => 'ten',
        ReadingMilestoneKind.twenty => 'twenty',
        ReadingMilestoneKind.khatam => 'khatam',
      };
}

ReadingMilestone? milestoneFor(CoverageUpdate update) {
  if (!update.counted) return null;
  if (update.khatam) {
    return const ReadingMilestone(
      kind: ReadingMilestoneKind.khatam,
      completedJuz: 30,
    );
  }
  if (update.completedJuz == null) return null;
  if (update.completedJuzCount == 10) {
    return const ReadingMilestone(
      kind: ReadingMilestoneKind.ten,
      completedJuz: 10,
    );
  }
  if (update.completedJuzCount == 20) {
    return const ReadingMilestone(
      kind: ReadingMilestoneKind.twenty,
      completedJuz: 20,
    );
  }
  return ReadingMilestone(
    kind: ReadingMilestoneKind.juz,
    completedJuz: update.completedJuzCount,
    juzNumber: update.completedJuz,
  );
}
