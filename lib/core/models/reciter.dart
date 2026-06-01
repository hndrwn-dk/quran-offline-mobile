/// Represents a Qur'an reciter whose per-ayah recitation audio is served from
/// the everyayah.com CDN.
///
/// Audio files follow the pattern `{baseUrl}/{SSS}{AAA}.mp3`, where `SSS` is the
/// zero-padded surah number (1-114) and `AAA` is the zero-padded ayah number,
/// e.g. `001001.mp3` for Al-Fatihah ayah 1.
class Reciter {
  /// Stable identifier, also used as the local storage folder name.
  /// Matches the everyayah.com data folder name.
  final String id;

  /// Display name in Latin script.
  final String name;

  /// Display name in Arabic script.
  final String arabicName;

  /// Base URL for the reciter's audio files (without a trailing slash).
  final String baseUrl;

  /// Approximate audio bitrate in kbps, shown to the user as a quality hint.
  final int bitrate;

  const Reciter({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.baseUrl,
    required this.bitrate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Reciter && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Static catalog of available reciters.
class ReciterCatalog {
  ReciterCatalog._();

  static const List<Reciter> reciters = [
    Reciter(
      id: 'Alafasy_128kbps',
      name: 'Mishary Rashid Alafasy',
      arabicName: 'مشاري راشد العفاسي',
      baseUrl: 'https://everyayah.com/data/Alafasy_128kbps',
      bitrate: 128,
    ),
    Reciter(
      id: 'Abdul_Basit_Murattal_192kbps',
      name: 'Abdul Basit (Murattal)',
      arabicName: 'عبد الباسط عبد الصمد',
      baseUrl: 'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps',
      bitrate: 192,
    ),
    Reciter(
      id: 'Abdurrahmaan_As-Sudais_192kbps',
      name: 'Abdurrahman As-Sudais',
      arabicName: 'عبد الرحمن السديس',
      baseUrl: 'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps',
      bitrate: 192,
    ),
    Reciter(
      id: 'Husary_128kbps',
      name: 'Mahmoud Khalil Al-Husary',
      arabicName: 'محمود خليل الحصري',
      baseUrl: 'https://everyayah.com/data/Husary_128kbps',
      bitrate: 128,
    ),
    Reciter(
      id: 'Minshawy_Murattal_128kbps',
      name: 'Mohamed Al-Minshawi (Murattal)',
      arabicName: 'محمد صديق المنشاوي',
      baseUrl: 'https://everyayah.com/data/Minshawy_Murattal_128kbps',
      bitrate: 128,
    ),
    Reciter(
      id: 'Saood_ash-Shuraym_128kbps',
      name: 'Saud Al-Shuraim',
      arabicName: 'سعود الشريم',
      baseUrl: 'https://everyayah.com/data/Saood_ash-Shuraym_128kbps',
      bitrate: 128,
    ),
  ];

  static const String defaultReciterId = 'Alafasy_128kbps';

  static Reciter byId(String id) {
    return reciters.firstWhere(
      (r) => r.id == id,
      orElse: () => reciters.first,
    );
  }
}
