/// Playlist of ayah numbers that may skip missing offline files.
class SparsePlaylist {
  const SparsePlaylist(this.ayahNos);

  final List<int> ayahNos;

  int get length => ayahNos.length;

  bool get isEmpty => ayahNos.isEmpty;

  int? ayahAt(int index) {
    if (index < 0 || index >= ayahNos.length) return null;
    return ayahNos[index];
  }

  int? indexOfAyah(int ayahNo) {
    final index = ayahNos.indexOf(ayahNo);
    return index < 0 ? null : index;
  }

  /// Exact ayah if present; otherwise the next available ayah; otherwise 0.
  int initialIndexFor(int startAyah) {
    final exact = indexOfAyah(startAyah);
    if (exact != null) return exact;
    for (var i = 0; i < ayahNos.length; i++) {
      if (ayahNos[i] >= startAyah) return i;
    }
    return 0;
  }
}

List<int> logicalAyahSequence({
  required bool hasBismillah,
  required int ayahCount,
}) {
  final ayahs = <int>[
    if (hasBismillah) 0,
  ];
  for (var ayah = 1; ayah <= ayahCount; ayah++) {
    ayahs.add(ayah);
  }
  return ayahs;
}
