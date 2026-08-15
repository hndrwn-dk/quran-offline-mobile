import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_offline/core/feedback/feedback_type.dart';
import 'package:quran_offline/core/feedback/github_feedback_service.dart';
import 'package:quran_offline/core/feedback/play_integrity_attestation.dart';

class _FakeAttestation implements PlayIntegrityAttestation {
  _FakeAttestation(this.token);

  final String? token;
  String? lastNonce;

  @override
  Future<String?> requestToken(String nonce) async {
    lastNonce = nonce;
    return token;
  }
}

void main() {
  group('GitHubFeedbackService', () {
    test('submit sends Play Integrity token and nonce in the JSON body', () async {
      late Map<String, dynamic> body;
      final attestation = _FakeAttestation('integrity-token');
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['x-feedback-ts'], isNull);
        expect(request.headers['x-feedback-nonce'], isNull);
        body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['type'], 'bug');
        expect(body['title'], 'Test title');
        expect(body['integrityToken'], 'integrity-token');
        expect(body['nonce'], 'fixed-nonce');
        return http.Response(
          jsonEncode({
            'issueUrl': 'https://github.com/hndrwn-dk/quran-offline-mobile/issues/1',
            'issueNumber': 1,
          }),
          201,
        );
      });

      final service = GitHubFeedbackService(
        client: client,
        attestation: attestation,
        nonceFactory: () => 'fixed-nonce',
      );
      final result = await service.submit(
        type: FeedbackType.bug,
        title: 'Test title',
        description: 'Details here',
        metadata: const {'language': 'en'},
      );
      service.dispose();

      expect(attestation.lastNonce, 'fixed-nonce');
      expect(result.isSuccess, isTrue);
      expect(result.issueNumber, 1);
      expect(result.issueUrl, contains('github.com'));
    });

    test('submit returns integrity_unavailable when Play cannot attest', () async {
      final client = MockClient((_) async {
        fail('API must not be called without an Integrity token');
      });
      final service = GitHubFeedbackService(
        client: client,
        attestation: _FakeAttestation(null),
        nonceFactory: () => 'fixed-nonce',
      );
      final result = await service.submit(
        type: FeedbackType.feature,
        title: 'Feature',
        description: 'Idea',
        metadata: const {},
      );
      service.dispose();

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'integrity_unavailable');
    });

    test('submit returns rate_limited on 429', () async {
      final client = MockClient((_) async => http.Response('{}', 429));
      final service = GitHubFeedbackService(
        client: client,
        attestation: _FakeAttestation('integrity-token'),
        nonceFactory: () => 'fixed-nonce',
      );
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
