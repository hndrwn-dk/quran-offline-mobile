import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/audio/setoran_speech_recognizer.dart';

void main() {
  test('detects Latin STT output as wrong language for Arabic check', () {
    expect(setoranTranscriptLooksLatin('call our own business'), isTrue);
    expect(setoranTranscriptLooksLatin('cool I want to be around me now'), isTrue);
    expect(setoranTranscriptLooksLatin('قل اعوذ برب الناس'), isFalse);
    expect(setoranTranscriptLooksLatin(''), isFalse);
  });
}
