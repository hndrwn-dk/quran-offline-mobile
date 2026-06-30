/// Optional verse context when reporting from Reader or Mushaf.
class FeedbackContext {
  const FeedbackContext({
    this.surahId,
    this.ayahNo,
    this.arabicSnippet,
  });

  final int? surahId;
  final int? ayahNo;
  final String? arabicSnippet;

  bool get hasVerse => surahId != null && ayahNo != null;
}
