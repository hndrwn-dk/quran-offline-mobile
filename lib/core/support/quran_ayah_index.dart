/// Hafs ayah positions used by the bundled verse JSON (6236 ayahs).
class QuranAyahIndex {
  QuranAyahIndex._();

  static const totalAyahs = 6236;

  static const surahAyahCounts = <int>[
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
    111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
    54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30,
    20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4,
    5, 6,
  ];

  /// First global index of each juz. Matches bundled `m.juz` on verse JSON.
  static const juzStartIndexes = <int>[
    0, 148, 259, 385, 516, 640, 750, 899, 1041, 1200, 1327, 1478, 1648, 1802,
    2029, 2214, 2483, 2673, 2875, 3214, 3385, 3563, 3732, 4089, 4264, 4510,
    4705, 5104, 5241, 5672,
  ];

  static final List<int> _surahOffsets = _offsets();

  static List<int> _offsets() {
    final offsets = List<int>.filled(114, 0);
    var cursor = 0;
    for (var i = 0; i < 114; i++) {
      offsets[i] = cursor;
      cursor += surahAyahCounts[i];
    }
    return offsets;
  }

  static int globalIndex(int surah, int ayah) {
    return _surahOffsets[surah - 1] + ayah - 1;
  }

  static int juzOf(int surah, int ayah) {
    return juzOfIndex(globalIndex(surah, ayah));
  }

  static int juzOfIndex(int index) {
    var juz = 1;
    for (var i = 1; i < juzStartIndexes.length; i++) {
      if (index >= juzStartIndexes[i]) juz = i + 1;
    }
    return juz;
  }

  static int juzAyahCount(int juz) {
    final start = juzStartIndexes[juz - 1];
    final end = juz == 30 ? totalAyahs : juzStartIndexes[juz];
    return end - start;
  }

  static Iterable<int> indexesInJuz(int juz) sync* {
    final start = juzStartIndexes[juz - 1];
    final end = juz == 30 ? totalAyahs : juzStartIndexes[juz];
    for (var index = start; index < end; index++) {
      yield index;
    }
  }
}
