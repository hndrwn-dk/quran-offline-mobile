import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/feedback/play_integrity_attestation.dart';
import 'package:quran_offline/core/feedback/play_integrity_verdict.dart';

void main() {
  Map<String, dynamic> payload({
    String packageName = kFeedbackAndroidPackage,
    String nonce = 'abc123nonce',
    String? timestampMillis,
    String appVerdict = 'PLAY_RECOGNIZED',
    List<String> deviceVerdicts = const ['MEETS_DEVICE_INTEGRITY'],
  }) {
    return {
      'requestDetails': {
        'requestPackageName': packageName,
        'nonce': nonce,
        'timestampMillis': timestampMillis ?? '1780000000000',
      },
      'appIntegrity': {
        'appRecognitionVerdict': appVerdict,
      },
      'deviceIntegrity': {
        'deviceRecognitionVerdict': deviceVerdicts,
      },
    };
  }

  group('evaluatePlayIntegrityVerdict', () {
    test('accepts Play-recognized app on a real device with matching nonce', () {
      expect(
        evaluatePlayIntegrityVerdict(
          payload: payload(),
          expectedNonce: 'abc123nonce',
          nowMs: 1780000000000,
        ),
        PlayIntegrityVerdict.ok,
      );
    });

    test('rejects sideload and unrecognized Play versions', () {
      expect(
        evaluatePlayIntegrityVerdict(
          payload: payload(appVerdict: 'UNRECOGNIZED_VERSION'),
          expectedNonce: 'abc123nonce',
          nowMs: 1780000000000,
        ),
        PlayIntegrityVerdict.notPlayRecognized,
      );
    });

    test('rejects nonce mismatch to block replay of another request', () {
      expect(
        evaluatePlayIntegrityVerdict(
          payload: payload(),
          expectedNonce: 'other-nonce',
          nowMs: 1780000000000,
        ),
        PlayIntegrityVerdict.nonceMismatch,
      );
    });

    test('rejects stale tokens', () {
      expect(
        evaluatePlayIntegrityVerdict(
          payload: payload(),
          expectedNonce: 'abc123nonce',
          nowMs: 1780000000000 + playIntegrityMaxAgeMs + 1,
        ),
        PlayIntegrityVerdict.stale,
      );
    });

    test('rejects wrong package name', () {
      expect(
        evaluatePlayIntegrityVerdict(
          payload: payload(packageName: 'com.example.fake'),
          expectedNonce: 'abc123nonce',
          nowMs: 1780000000000,
        ),
        PlayIntegrityVerdict.wrongPackage,
      );
    });

    test('rejects devices that meet neither device nor basic integrity', () {
      expect(
        evaluatePlayIntegrityVerdict(
          payload: payload(deviceVerdicts: const ['MEETS_VIRTUAL_INTEGRITY']),
          expectedNonce: 'abc123nonce',
          nowMs: 1780000000000,
        ),
        PlayIntegrityVerdict.weakDevice,
      );
    });
  });

  test('generatePlayIntegrityNonce is URL-safe Base64 without padding', () {
    final nonce = generatePlayIntegrityNonce();
    expect(nonce, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    expect(nonce.contains('='), isFalse);
    expect(nonce.length, greaterThanOrEqualTo(32));
  });
}
