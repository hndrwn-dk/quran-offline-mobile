sealed class ReaderSource {
  const ReaderSource();
}

class SurahSource extends ReaderSource {
  final int surahId;
  const SurahSource(this.surahId);
}

class JuzSource extends ReaderSource {
  final int juzNo;
  const JuzSource(this.juzNo);
}

class PageSource extends ReaderSource {
  final int pageNo;
  const PageSource(this.pageNo);
}

