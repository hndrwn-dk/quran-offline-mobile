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
  
  /// Check if a surah should have Bismillah
  /// - Surah 1 (Al-Fatiha): No, because Ayah 1:1 IS the Bismillah
  /// - Surah 9 (At-Taubah): No, this surah doesn't start with Bismillah
  /// - All other surahs: Yes, show Bismillah before first ayah
  static bool shouldShowBismillah(int surahId) {
    return surahId != 1 && surahId != 9;
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

