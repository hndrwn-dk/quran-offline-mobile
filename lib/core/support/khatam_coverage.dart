import 'dart:typed_data';

import 'package:quran_offline/core/support/quran_ayah_index.dart';

class CoverageUpdate {
  const CoverageUpdate({
    required this.counted,
    required this.completedJuz,
    required this.completedJuzCount,
    required this.khatam,
    required this.cycle,
  });

  final bool counted;
  final int? completedJuz;
  final int completedJuzCount;
  final bool khatam;

  /// Cycle the ayah belonged to. After khatam this is the finished cycle.
  final int cycle;
}

/// Unique ayahs read in the current khatam cycle. 6236 bits, local only.
class KhatamCoverage {
  KhatamCoverage({int cycle = 1, Uint8List? bits})
      : cycle = cycle,
        bits = bits ?? Uint8List(byteLength) {
    markedCount = _countSet(this.bits);
    _completed = _completedJuzCount();
  }

  static const byteLength = 780;

  final Uint8List bits;
  int cycle;
  int markedCount = 0;
  int _completed = 0;

  factory KhatamCoverage.fromBytes(Uint8List raw, {int cycle = 1}) {
    final bits = Uint8List(byteLength);
    if (raw.length == byteLength) {
      bits.setAll(0, raw);
    }
    return KhatamCoverage(cycle: cycle, bits: bits);
  }

  Uint8List toBytes() => Uint8List.fromList(bits);

  CoverageUpdate mark(int surah, int ayah) {
    return markIndex(QuranAyahIndex.globalIndex(surah, ayah));
  }

  CoverageUpdate markIndex(int index) {
    if (_isSet(index)) {
      return CoverageUpdate(
        counted: false,
        completedJuz: null,
        completedJuzCount: _completed,
        khatam: false,
        cycle: cycle,
      );
    }
    _set(index);
    markedCount++;
    final juz = QuranAyahIndex.juzOfIndex(index);
    final juzDone = _isJuzComplete(juz);
    if (juzDone) _completed++;
    if (markedCount == QuranAyahIndex.totalAyahs) {
      final finished = cycle;
      bits.fillRange(0, bits.length, 0);
      markedCount = 0;
      _completed = 0;
      cycle += 1;
      return CoverageUpdate(
        counted: true,
        completedJuz: null,
        completedJuzCount: 30,
        khatam: true,
        cycle: finished,
      );
    }
    return CoverageUpdate(
      counted: true,
      completedJuz: juzDone ? juz : null,
      completedJuzCount: _completed,
      khatam: false,
      cycle: cycle,
    );
  }

  bool _isJuzComplete(int juz) {
    for (final index in QuranAyahIndex.indexesInJuz(juz)) {
      if (!_isSet(index)) return false;
    }
    return true;
  }

  int _completedJuzCount() {
    var count = 0;
    for (var juz = 1; juz <= 30; juz++) {
      if (_isJuzComplete(juz)) count++;
    }
    return count;
  }

  bool _isSet(int index) => (bits[index >> 3] & (1 << (index & 7))) != 0;

  void _set(int index) {
    bits[index >> 3] |= 1 << (index & 7);
  }

  static int _countSet(Uint8List bits) {
    var count = 0;
    for (var index = 0; index < QuranAyahIndex.totalAyahs; index++) {
      if ((bits[index >> 3] & (1 << (index & 7))) != 0) count++;
    }
    return count;
  }
}
