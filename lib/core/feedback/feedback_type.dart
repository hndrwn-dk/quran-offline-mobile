/// In-app feedback category mapped to GitHub issue labels.
enum FeedbackType {
  /// Label: `new feature`
  feature,

  /// Label: `bug`
  bug,
}

extension FeedbackTypeApi on FeedbackType {
  String get apiValue => switch (this) {
        FeedbackType.feature => 'feature',
        FeedbackType.bug => 'bug',
      };
}
