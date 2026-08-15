import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/audio/sparse_playlist.dart';
import 'package:quran_offline/core/utils/bismillah.dart';

void main() {
  group('logicalAyahSequence', () {
    test('includes bismillah then ayahs for Al-Baqarah', () {
      expect(
        logicalAyahSequence(hasBismillah: true, ayahCount: 5),
        [0, 1, 2, 3, 4, 5],
      );
    });

    test('omits bismillah for Al-Fatiha', () {
      expect(
        logicalAyahSequence(hasBismillah: false, ayahCount: 7),
        [1, 2, 3, 4, 5, 6, 7],
      );
    });
  });

  group('SparsePlaylist', () {
    test('contiguous playlist still maps index to ayah like Bismillah helpers', () {
      final playlist = SparsePlaylist(
        logicalAyahSequence(hasBismillah: true, ayahCount: 7),
      );
      expect(playlist.ayahAt(0), Bismillah.audioAyahNo);
      expect(playlist.ayahAt(6), 6);
      expect(playlist.indexOfAyah(6), 6);
      expect(
        playlist.ayahAt(Bismillah.playlistIndex(2, 6)),
        6,
      );
    });

    test('skipped missing ayahs do not shift later ayah numbers', () {
      // Offline: bismillah + 1,2 present; 3-4 missing; 5 present.
      const playlist = SparsePlaylist([0, 1, 2, 5]);

      expect(playlist.ayahAt(0), 0);
      expect(playlist.ayahAt(1), 1);
      expect(playlist.ayahAt(2), 2);
      expect(playlist.ayahAt(3), 5);

      expect(playlist.indexOfAyah(5), 3);
      expect(playlist.indexOfAyah(3), isNull);

      // Contiguous mapping would claim index 3 is ayah 3.
      expect(Bismillah.ayahFromPlaylistIndex(2, 3), 3);
      expect(playlist.ayahAt(3), isNot(3));
    });

    test('initialIndex prefers exact ayah then next available', () {
      const playlist = SparsePlaylist([0, 1, 2, 5, 6]);
      expect(playlist.initialIndexFor(5), 3);
      expect(playlist.initialIndexFor(3), 3); // 3 missing -> 5
      expect(playlist.initialIndexFor(0), 0);
      expect(playlist.initialIndexFor(99), 0);
    });
  });
}
