/// One glyph word on a QPC V2 Mushaf line.
class QpcV2Word {
  const QpcV2Word({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.word,
    required this.glyph,
    required this.location,
  });

  final int id;
  final int surah;
  final int ayah;
  final int word;
  final String glyph;
  final String location;

  String get ayahKey => '$surah:$ayah';
}

/// A rendered line on a Mushaf page (layout DB + words DB).
class QpcV2Line {
  const QpcV2Line({
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    this.surahId,
    this.words = const [],
  });

  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final int? surahId;
  final List<QpcV2Word> words;

  bool get isSurahName => lineType == 'surah_name';
  bool get isBasmallah => lineType == 'basmallah';
  bool get isAyah => lineType == 'ayah';

  String get glyphText => words.map((w) => w.glyph).join();
}

/// Full page payload for the Mushaf renderer.
class QpcV2PageContent {
  const QpcV2PageContent({
    required this.pageNumber,
    required this.lines,
    required this.fontFamily,
    required this.basmallahFontFamily,
    required this.bismillahGlyphText,
  });

  final int pageNumber;
  final List<QpcV2Line> lines;
  final String fontFamily;

  /// Page-1 QPC V2 font renders Bismillah PUA glyphs on every page.
  final String basmallahFontFamily;
  final String bismillahGlyphText;
}
