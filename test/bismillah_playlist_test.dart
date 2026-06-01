import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/bismillah.dart';

void main() {
  group('Bismillah playlist mapping (Al-Baqarah)', () {
    const surahId = 2;

    test('round-trip index <-> ayah for bismillah surah', () {
      expect(Bismillah.playlistIndex(surahId, Bismillah.audioAyahNo), 0);
      expect(
        Bismillah.ayahFromPlaylistIndex(surahId, 0),
        Bismillah.audioAyahNo,
      );

      for (var ayah = 1; ayah <= 10; ayah++) {
        final index = Bismillah.playlistIndex(surahId, ayah);
        expect(index, ayah, reason: 'ayah $ayah');
        expect(
          Bismillah.ayahFromPlaylistIndex(surahId, index),
          ayah,
          reason: 'index $index',
        );
      }
    });

    test('mushaf ayah 6 maps to playlist index 6 (not bismillah)', () {
      expect(Bismillah.playlistIndex(surahId, 6), 6);
      expect(Bismillah.ayahFromPlaylistIndex(surahId, 6), 6);
      expect(Bismillah.ayahFromPlaylistIndex(surahId, 6), isNot(0));
    });

    test('playAyahExact start ayah is not rewritten to bismillah', () {
      expect(Bismillah.playStartAyah(surahId, 6), 6);
      expect(Bismillah.playStartAyah(surahId, 1), Bismillah.audioAyahNo);
    });
  });

  group('Bismillah playlist mapping (Al-Fatiha)', () {
    const surahId = 1;

    test('no separate bismillah track', () {
      expect(Bismillah.hasBismillahAudio(surahId), isFalse);
      expect(Bismillah.playlistIndex(surahId, 1), 0);
      expect(Bismillah.ayahFromPlaylistIndex(surahId, 0), 1);
      expect(Bismillah.ayahFromPlaylistIndex(surahId, 6), 7);
    });
  });
}
