import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_offline/core/feedback/feedback_type.dart';
import 'package:quran_offline/core/feedback/github_feedback_service.dart';

void main() {
  group('GitHubFeedbackService', () {
    test('submit returns success on 201 response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['type'], 'bug');
        expect(body['title'], 'Test title');
        return http.Response(
          jsonEncode({
            'issueUrl': 'https://github.com/hndrwn-dk/quran-offline-mobile/issues/1',
            'issueNumber': 1,
          }),
          201,
        );
      });

      final service = GitHubFeedbackService(client: client);
      final result = await service.submit(
        type: FeedbackType.bug,
        title: 'Test title',
        description: 'Details here',
        metadata: const {'language': 'en'},
      );
      service.dispose();

      expect(result.isSuccess, isTrue);
      expect(result.issueNumber, 1);
      expect(result.issueUrl, contains('github.com'));
    });

    test('submit returns rate_limited on 429', () async {
      final client = MockClient((_) async => http.Response('{}', 429));
      final service = GitHubFeedbackService(client: client);
      final result = await service.submit(
        type: FeedbackType.feature,
        title: 'Feature',
        description: 'Idea',
        metadata: const {},
      );
      service.dispose();

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'rate_limited');
    });
  });
}
