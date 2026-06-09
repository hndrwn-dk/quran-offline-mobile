enum SetoranCheckFeedbackKind {
  correct,
  incorrect,
  uncertain,
  wrongLanguage,
  empty,
}

class SetoranCheckFeedback {
  const SetoranCheckFeedback({
    required this.kind,
    this.transcript = '',
    this.score,
  });

  final SetoranCheckFeedbackKind kind;
  final String transcript;
  final double? score;

  factory SetoranCheckFeedback.fromVerdict({
    required SetoranCheckFeedbackKind kind,
    required String transcript,
    double? score,
  }) {
    return SetoranCheckFeedback(
      kind: kind,
      transcript: transcript,
      score: score,
    );
  }
}
