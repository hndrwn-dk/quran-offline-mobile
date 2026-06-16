/// One glyph word on a QPC V4 Mushaf line.
class QpcV4Word {
  const QpcV4Word({
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
class QpcV4Line {
  const QpcV4Line({
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
  final List<QpcV4Word> words;

  bool get isSurahName => lineType == 'surah_name';
  bool get isBasmallah => lineType == 'basmallah';
  bool get isAyah => lineType == 'ayah';

  String get glyphText => words.map((w) => w.glyph).join();
}

/// Full page payload for the Mushaf renderer.
class QpcV4PageContent {
  const QpcV4PageContent({
    required this.pageNumber,
    required this.lines,
    required this.fontFamily,
  });

  final int pageNumber;
  final List<QpcV4Line> lines;
  final String fontFamily;
}
