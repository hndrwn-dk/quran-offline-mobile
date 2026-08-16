/// Quran Arabic font families bundled in the app.

class QuranFonts {

  QuranFonts._();



  static const uthmanicHafsV22 = 'UthmanicHafsV22';

  static const kfgqpcUthmanic = 'KFGQPCUthmanic';

  /// QUL #247 Digital Khatt V2 (SIL OFL 1.1). Used by Surah/Juz Reader AyahCard.
  /// Local GPOS: small-high waqf/saktah (U+06D6–06DC) and 06E8/06EC attach to space at Y=1100.
  /// After saktah (smallhighseen) the following space is widened so a nearby qala/waqf
  /// sits beside it instead of overlapping (e.g. 36:52). Harakat unchanged. Mushaf unused.
  static const digitalKhattV2 = 'DigitalKhattV2';

  static const qpcV2Page50 = 'QpcV2Page50';

  static const scheherazade = 'ScheherazadeNew';



  /// Fonts to compare on the dev spike screen (Settings → Bandingkan font Arab).

  static const compareCandidates = <String, String>{

    uthmanicHafsV22: 'QPC Hafs / Uthmanic Hafs V22 (app default, QUL #245)',

    kfgqpcUthmanic: 'KFGQPC Uthmanic Script HAFS (King Fahd Complex)',

    digitalKhattV2: 'Digital Khatt V2 — Madinah 1421H Unicode (QUL #247)',

  };

}

