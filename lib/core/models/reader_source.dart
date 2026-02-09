sealed class ReaderSource {
  const ReaderSource();
}

class SurahSource extends ReaderSource {
  final int surahId;
  final int? targetAyahNo;
  const SurahSource(this.surahId, {this.targetAyahNo});
}

class JuzSource extends ReaderSource {
  final int juzNo;
  const JuzSource(this.juzNo);
}

class PageSource extends ReaderSource {
  final int pageNo;
  const PageSource(this.pageNo);
}

class SurahInJuzSource extends ReaderSource {
  final int juzNo;
  final int surahId;
  const SurahInJuzSource(this.juzNo, this.surahId);
}

