/// Utility class for Bismillah text
class Bismillah {
  /// Arabic text of Bismillahirrahmanirrahim
  static const String arabic = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
  
  /// Transliteration
  static const String transliteration = 'Bismillahirrahmanirrahim';
  
  /// English translation
  static const String english = 'In the name of Allah, the Most Gracious, the Most Merciful';
  
  /// Indonesian translation
  static const String indonesian = 'Dengan nama Allah, Yang Maha Pengasih, Maha Penyayang';
  
  /// Chinese translation
  static const String chinese = '奉至仁至慈的真主之名';
  
  /// Japanese translation
  static const String japanese = '慈悲あまねく慈愛深きアッラーの御名において';
  
  /// Playlist / player value for the standalone Bismillah clip (everyayah `{SSS}000.mp3`).
  static const int audioAyahNo = 0;

  /// Check if a surah should have Bismillah
  /// - Surah 1 (Al-Fatiha): No, because Ayah 1:1 IS the Bismillah
  /// - Surah 9 (At-Taubah): No, this surah doesn't start with Bismillah
  /// - All other surahs: Yes, show Bismillah before first ayah
  static bool shouldShowBismillah(int surahId) {
    return surahId != 1 && surahId != 9;
  }

  /// Whether this surah has a separate Bismillah MP3 on everyayah.com.
  static bool hasBismillahAudio(int surahId) => shouldShowBismillah(surahId);

  /// Maps logical ayah ([audioAyahNo] or 1..N) to playlist index.
  static int playlistIndex(int surahId, int ayahNo) {
    if (!hasBismillahAudio(surahId)) return ayahNo - 1;
    return ayahNo;
  }

  /// Maps playlist index to logical ayah ([audioAyahNo] or 1..N).
  static int ayahFromPlaylistIndex(int surahId, int index) {
    if (!hasBismillahAudio(surahId)) return index + 1;
    return index;
  }

  /// Start index when playing the surah from the beginning.
  static int playSurahStartAyah(int surahId) =>
      hasBismillahAudio(surahId) ? audioAyahNo : 1;

  /// Start ayah when user taps play on an ayah row (or [audioAyahNo] for Bismillah only).
  static int playStartAyah(int surahId, int tappedAyahNo) {
    if (tappedAyahNo == audioAyahNo) return audioAyahNo;
    if (tappedAyahNo == 1 && hasBismillahAudio(surahId)) return audioAyahNo;
    return tappedAyahNo;
  }
  
  /// Get translation based on language code
  static String getTranslation(String lang) {
    return switch (lang) {
      'en' => english,
      'id' => indonesian,
      'zh' => chinese,
      'ja' => japanese,
      _ => indonesian,
    };
  }
}

