import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/feedback/feedback_proof_of_work.dart';

void main() {
  group('neutralizeGithubMentions', () {
    test('breaks @user mentions that would ping GitHub accounts', () {
      expect(
        neutralizeGithubMentions('See @octocat and @@admin'),
        isNot(contains('@octocat')),
      );
      expect(neutralizeGithubMentions('See @octocat'), contains('octocat'));
    });

    test('leaves emails and ayah refs intact', () {
      expect(
        neutralizeGithubMentions('Email a@b.com about 2:255'),
        contains('a@b.com'),
      );
    });
  });

  group('feedbackProofOfWork', () {
    test('solved nonce verifies and a wrong nonce does not', () {
      const ts = 1780000000000;
      final nonce = solveFeedbackProofOfWork(timestampMs: ts);
      expect(
        verifyFeedbackProofOfWork(
          timestampMs: ts,
          nonce: nonce,
          nowMs: ts,
        ),
        isTrue,
      );
      expect(
        verifyFeedbackProofOfWork(
          timestampMs: ts,
          nonce: nonce + 1,
          nowMs: ts,
        ),
        isFalse,
      );
      expect(
        verifyFeedbackProofOfWork(
          timestampMs: ts,
          nonce: nonce,
          nowMs: ts + feedbackPowMaxAgeMs + 1,
        ),
        isFalse,
      );
    });
  });
}
