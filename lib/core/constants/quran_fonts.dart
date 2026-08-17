/// Quran Arabic font families bundled in the app.
class QuranFonts {
  QuranFonts._();

  static const uthmanicHafsV22 = 'UthmanicHafsV22';

  static const kfgqpcUthmanic = 'KFGQPCUthmanic';

  /// QUL #247 Digital Khatt V2 (SIL OFL 1.1). Default for non-Mushaf Arabic.
  /// Local GPOS: small-high waqf/saktah (U+06D6–06DC) and 06E8/06EC attach to
  /// space at Y=1100; space after saktah is widened so qala/waqf sit beside it
  /// (e.g. 36:52). Mushaf keeps Uthmanic / QPC V2 separately.
  static const digitalKhattV2 = 'DigitalKhattV2';

  static const qpcV2Page50 = 'QpcV2Page50';

  static const scheherazade = 'ScheherazadeNew';

  static const digitalKhattFallbacks = <String>[
    uthmanicHafsV22,
    'UthmanicHafs',
    kfgqpcUthmanic,
    scheherazade,
  ];

  static const uthmanicFallbacks = <String>[
    'UthmanicHafs',
    kfgqpcUthmanic,
    scheherazade,
  ];

  /// Fonts to compare on the dev spike screen (Settings → Bandingkan font Arab).
  static const compareCandidates = <String, String>{
    uthmanicHafsV22: 'QPC Hafs / Uthmanic Hafs V22 (Mushaf fallback, QUL #245)',
    kfgqpcUthmanic: 'KFGQPC Uthmanic Script HAFS (King Fahd Complex)',
    digitalKhattV2: 'Digital Khatt V2 — Madinah 1421H Unicode (QUL #247, app default)',
  };
}
