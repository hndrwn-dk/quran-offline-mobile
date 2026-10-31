import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ResumeHintMode { surah, juz, page }

/// Position restored by tapping the Continue card, used for the hint chip.
class ResumeHint {
  const ResumeHint.surah({required this.surahId, required this.ayahNo})
      : mode = ResumeHintMode.surah,
        pageNo = null,
        juzNo = null;

  const ResumeHint.juz({required this.juzNo, this.surahId, this.ayahNo})
      : mode = ResumeHintMode.juz,
        pageNo = null;

  const ResumeHint.page({required this.pageNo})
      : mode = ResumeHintMode.page,
        surahId = null,
        ayahNo = null,
        juzNo = null;

  final ResumeHintMode mode;
  final int? surahId;
  final int? ayahNo;
  final int? pageNo;
  final int? juzNo;
}

final resumeHintProvider = StateProvider<ResumeHint?>((ref) => null);
