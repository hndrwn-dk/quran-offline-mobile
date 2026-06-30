import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quran_offline/core/constants/feedback_api.dart';
import 'package:quran_offline/core/feedback/feedback_type.dart';

class FeedbackSubmitResult {
  const FeedbackSubmitResult.success({
    required this.issueUrl,
    required this.issueNumber,
  }) : errorMessage = null;

  const FeedbackSubmitResult.failure(this.errorMessage)
      : issueUrl = null,
        issueNumber = null;

  final String? issueUrl;
  final int? issueNumber;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null;
}

/// Submits in-app feedback to the Vercel proxy that creates GitHub Issues.
class GitHubFeedbackService {
  GitHubFeedbackService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<FeedbackSubmitResult> submit({
    required FeedbackType type,
    required String title,
    required String description,
    required Map<String, dynamic> metadata,
  }) async {
    final uri = Uri.parse(FeedbackApi.endpoint);
    final payload = jsonEncode({
      'type': type.apiValue,
      'title': title.trim(),
      'description': description.trim(),
      'metadata': metadata,
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final issueUrl = decoded['issueUrl'] as String?;
        final issueNumber = decoded['issueNumber'];
        if (issueUrl != null && issueNumber is int) {
          return FeedbackSubmitResult.success(
            issueUrl: issueUrl,
            issueNumber: issueNumber,
          );
        }
        return const FeedbackSubmitResult.failure('Invalid server response');
      }

      if (response.statusCode == 429) {
        return const FeedbackSubmitResult.failure('rate_limited');
      }

      return FeedbackSubmitResult.failure('http_${response.statusCode}');
    } catch (_) {
      return const FeedbackSubmitResult.failure('network');
    }
  }

  void dispose() {
    _client.close();
  }
}
