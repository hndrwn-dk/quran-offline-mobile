/// Vercel feedback API endpoint.
///
/// After deploying `api/feedback.ts`, set this to your production URL.
class FeedbackApi {
  FeedbackApi._();

  /// POST target for in-app feedback submissions.
  static const String endpoint =
      'https://quran-offline-indol.vercel.app/api/feedback';
}
