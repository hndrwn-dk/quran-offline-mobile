import 'package:quran_offline/core/providers/last_read_provider.dart';

/// The position that was actually completed (dwell-gated), persisted so the
/// Continue card can show its completed state after a restart.
class CompletedReading {
  const CompletedReading({
    required this.type,
    required this.id,
    this.ayahNo,
    this.surahId,
    this.pageNo,
  });

  final String type;
  final int id;
  final int? ayahNo;
  final int? surahId;
  final int? pageNo;

  bool matches(LastReadPosition position) {
    if (position.type != type || position.id != id) return false;
    if (type == 'page') return true;
    if (type == 'juz') {
      return position.ayahNo == ayahNo && position.surahId == surahId;
    }
    return position.ayahNo == ayahNo;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'ayahNo': ayahNo,
      'surahId': surahId,
      'pageNo': pageNo,
    };
  }

  factory CompletedReading.fromJson(Map<String, dynamic> json) {
    return CompletedReading(
      type: json['type'] as String,
      id: json['id'] as int,
      ayahNo: json['ayahNo'] as int?,
      surahId: json['surahId'] as int?,
      pageNo: json['pageNo'] as int?,
    );
  }
}
