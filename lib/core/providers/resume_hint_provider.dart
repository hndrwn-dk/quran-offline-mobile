import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ResumeHintMode { surah, page }

/// Position restored by the cold-start resume, used for the hint chip.
class ResumeHint {
  const ResumeHint.surah({required this.surahId, required this.ayahNo})
      : mode = ResumeHintMode.surah,
        pageNo = null;

  const ResumeHint.page({required this.pageNo})
      : mode = ResumeHintMode.page,
        surahId = null,
        ayahNo = null;

  final ResumeHintMode mode;
  final int? surahId;
  final int? ayahNo;
  final int? pageNo;
}

final resumeHintProvider = StateProvider<ResumeHint?>((ref) => null);
