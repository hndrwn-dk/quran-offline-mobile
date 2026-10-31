import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/reading/reading_completion_gate.dart';

void main() {
  group('ReadingCompletionGate', () {
    test('Al-Falaq closed after 2s is not completed', () {
      var now = DateTime.utc(2026, 10, 31, 12);
      final gate = ReadingCompletionGate(
        minimumSession: const Duration(seconds: 10),
        clock: () => now,
      )..startSession();

      gate.setEndVisible(true);
      now = now.add(const Duration(seconds: 2));
      expect(gate.tick(), isFalse);

      gate.dispose();
      now = now.add(const Duration(seconds: 30));
      expect(gate.tick(), isFalse);
    });

    test('Al-Falaq with the last ayah visible for 10s is completed', () {
      var now = DateTime.utc(2026, 10, 31, 12);
      final gate = ReadingCompletionGate(
        minimumSession: const Duration(seconds: 10),
        clock: () => now,
      )..startSession();

      gate.setEndVisible(true);
      now = now.add(const Duration(seconds: 10));
      expect(gate.tick(), isTrue);
      expect(gate.completed, isTrue);
    });

    test('Al-Baqarah fast-scrolled and closed within 3s is not completed', () {
      var now = DateTime.utc(2026, 10, 31, 12);
      final gate = ReadingCompletionGate(
        minimumSession: const Duration(seconds: 20),
        clock: () => now,
      )..startSession();

      gate.setEndVisible(true);
      now = now.add(const Duration(seconds: 3));
      expect(gate.tick(), isFalse);
    });

    test('mushaf final page for 4s is completed', () {
      var now = DateTime.utc(2026, 10, 31, 12);
      final gate = ReadingCompletionGate(
        minimumSession: Duration.zero,
        clock: () => now,
      )..startSession();

      gate.setEndVisible(true);
      now = now.add(const Duration(seconds: 4));
      expect(gate.tick(), isTrue);
    });

    test('hiding and re-showing the end restarts the 3s dwell', () {
      var now = DateTime.utc(2026, 10, 31, 12);
      final gate = ReadingCompletionGate(
        minimumSession: Duration.zero,
        clock: () => now,
      )..startSession();

      gate.setEndVisible(true);
      now = now.add(const Duration(seconds: 2));
      gate.setEndVisible(false);
      now = now.add(const Duration(seconds: 2));
      gate.setEndVisible(true);
      now = now.add(const Duration(seconds: 2));
      expect(gate.tick(), isFalse);

      now = now.add(const Duration(seconds: 1));
      expect(gate.tick(), isTrue);
    });

    test('a 2s dwell is never enough, even in a long session', () {
      var now = DateTime.utc(2026, 10, 31, 12);
      final gate = ReadingCompletionGate(
        minimumSession: Duration.zero,
        clock: () => now,
      )..startSession();

      now = now.add(const Duration(minutes: 2));
      gate.setEndVisible(true);
      now = now.add(const Duration(seconds: 2));
      expect(gate.tick(), isFalse);
    });
  });
}
