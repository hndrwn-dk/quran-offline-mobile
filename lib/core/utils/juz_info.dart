/// Utility class for Juz-related information.
class JuzInfo {
  /// Map of Juz number to total ayah count.
  static const Map<int, int> totalAyahCounts = {
    1: 148,
    2: 111,
    3: 126,
    4: 131,
    5: 124,
    6: 110,
    7: 149,
    8: 142,
    9: 159,
    10: 128,
    11: 151,
    12: 170,
    13: 154,
    14: 227,
    15: 185,
    16: 269,
    17: 190,
    18: 202,
    19: 339,
    20: 171,
    21: 178,
    22: 169,
    23: 357,
    24: 175,
    25: 246,
    26: 195,
    27: 399,
    28: 137,
    29: 431,
    30: 564,
  };

  /// Get total ayah count for a given Juz number.
  /// Returns null if Juz number is invalid.
  static int? getTotalAyah(int juzNo) {
    return totalAyahCounts[juzNo];
  }
}

