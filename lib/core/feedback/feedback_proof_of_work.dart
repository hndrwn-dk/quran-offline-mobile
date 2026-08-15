import 'dart:convert';

import 'package:crypto/crypto.dart';

const feedbackPowPrefix = 'quran-offline';
const feedbackPowZeroNibbles = 4;
const feedbackPowMaxAgeMs = 5 * 60 * 1000;

const feedbackTsHeader = 'X-Feedback-Ts';
const feedbackNonceHeader = 'X-Feedback-Nonce';

/// Inserts a zero-width space after @ so GitHub does not notify the user.
String neutralizeGithubMentions(String text) {
  return text.replaceAllMapped(
    RegExp(r'(^|[^A-Za-z0-9_])@([A-Za-z0-9-]{1,39})\b'),
    (match) => '${match[1]}@\u200b${match[2]}',
  );
}

Digest _powDigest(int timestampMs, int nonce) {
  return sha256.convert(
    utf8.encode('$feedbackPowPrefix:$timestampMs:$nonce'),
  );
}

bool _hasLeadingZeroNibbles(Digest digest, int nibbles) {
  var remaining = nibbles;
  for (final byte in digest.bytes) {
    if (remaining <= 0) return true;
    if (remaining >= 2) {
      if (byte != 0) return false;
      remaining -= 2;
      continue;
    }
    return (byte >> 4) == 0;
  }
  return remaining <= 0;
}

bool verifyFeedbackProofOfWork({
  required int timestampMs,
  required int nonce,
  int? nowMs,
}) {
  if (nonce < 0) return false;
  final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  if ((now - timestampMs).abs() > feedbackPowMaxAgeMs) return false;
  final digest = _powDigest(timestampMs, nonce);
  return _hasLeadingZeroNibbles(digest, feedbackPowZeroNibbles);
}

int solveFeedbackProofOfWork({
  required int timestampMs,
}) {
  var nonce = 0;
  while (true) {
    final digest = _powDigest(timestampMs, nonce);
    if (_hasLeadingZeroNibbles(digest, feedbackPowZeroNibbles)) {
      return nonce;
    }
    nonce++;
  }
}
