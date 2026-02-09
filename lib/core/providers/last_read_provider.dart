import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_offline/core/models/reader_source.dart';

/// Model for last read position
class LastReadPosition {
  final String type; // 'surah', 'juz', 'page', or 'surah_in_juz'
  final int id; // surahId, juzNo, or pageNo
  final int? ayahNo; // For surah/juz: ayahNo, for page: ayahNo (with surahId)
  final int? surahId; // For page: surahId of the ayah, for surah_in_juz: juzNo, null for surah/juz
  final DateTime timestamp;

  LastReadPosition({
    required this.type,
    required this.id,
    this.ayahNo,
    this.surahId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'ayahNo': ayahNo,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LastReadPosition.fromJson(Map<String, dynamic> json) {
    return LastReadPosition(
      type: json['type'] as String,
      id: json['id'] as int,
      ayahNo: json['ayahNo'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to ReaderSource
  ReaderSource toReaderSource() {
    return switch (type) {
      'surah' => SurahSource(id, targetAyahNo: ayahNo),
      'juz' => JuzSource(id),
      'page' => PageSource(id),
      'surah_in_juz' => SurahInJuzSource(surahId ?? id, id), // surahId stores juzNo, id stores surahId
      _ => throw ArgumentError('Unknown type: $type'),
    };
  }
}

class LastReadNotifier extends StateNotifier<LastReadPosition?> {
  LastReadNotifier() : super(null) {
    _loadLastRead();
  }

  static const String _key = 'last_read_position';

  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final type = prefs.getString('${_key}_type');
    final id = prefs.getInt('${_key}_id');
    final ayahNo = prefs.getInt('${_key}_ayahNo');
    final surahId = prefs.getInt('${_key}_surahId');
    final timestampStr = prefs.getString('${_key}_timestamp');
    
    if (type != null && id != null && timestampStr != null) {
      try {
        state = LastReadPosition(
          type: type,
          id: id,
          ayahNo: ayahNo,
          surahId: surahId,
          timestamp: DateTime.parse(timestampStr),
        );
      } catch (e) {
        // Invalid data, ignore
        state = null;
      }
    }
  }

  Future<void> saveLastRead(ReaderSource source, {int? ayahNo, int? surahId}) async {
    final prefs = await SharedPreferences.getInstance();
    
    final lastRead = switch (source) {
      SurahSource(:final surahId) => LastReadPosition(
          type: 'surah',
          id: surahId,
          ayahNo: ayahNo,
          surahId: null, // Not needed for surah
          timestamp: DateTime.now(),
        ),
      JuzSource(:final juzNo) => LastReadPosition(
          type: 'juz',
          id: juzNo,
          ayahNo: ayahNo,
          surahId: null, // Not needed for juz
          timestamp: DateTime.now(),
        ),
      PageSource(:final pageNo) => LastReadPosition(
          type: 'page',
          id: pageNo,
          ayahNo: ayahNo,
          surahId: surahId, // Needed for page to identify which surah
          timestamp: DateTime.now(),
        ),
      SurahInJuzSource(:final juzNo, :final surahId) => LastReadPosition(
          type: 'surah_in_juz',
          id: surahId,
          ayahNo: ayahNo,
          surahId: juzNo, // Store juzNo in surahId field for SurahInJuzSource
          timestamp: DateTime.now(),
        ),
    };

    // Save to SharedPreferences
    await prefs.setString('${_key}_type', lastRead.type);
    await prefs.setInt('${_key}_id', lastRead.id);
    if (lastRead.ayahNo != null) {
      await prefs.setInt('${_key}_ayahNo', lastRead.ayahNo!);
    } else {
      await prefs.remove('${_key}_ayahNo');
    }
    if (lastRead.surahId != null) {
      await prefs.setInt('${_key}_surahId', lastRead.surahId!);
    } else {
      await prefs.remove('${_key}_surahId');
    }
    await prefs.setString('${_key}_timestamp', lastRead.timestamp.toIso8601String());
    
    state = lastRead;
  }

  Future<void> clearLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_key}_type');
    await prefs.remove('${_key}_id');
    await prefs.remove('${_key}_ayahNo');
    await prefs.remove('${_key}_surahId');
    await prefs.remove('${_key}_timestamp');
    state = null;
  }
}

final lastReadProvider = StateNotifierProvider<LastReadNotifier, LastReadPosition?>((ref) {
  return LastReadNotifier();
});

