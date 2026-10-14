import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/support/ayah_dwell.dart';
import 'package:quran_offline/core/support/khatam_coverage.dart';
import 'package:quran_offline/core/support/quran_ayah_index.dart';
import 'package:quran_offline/core/support/reading_coverage_controller.dart';
import 'package:quran_offline/core/support/reading_milestone.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('debounces bitset writes and ignores a repeat read', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = ReadingCoverageController(
      prefs: prefs,
      writeDelay: const Duration(milliseconds: 20),
      clock: () => DateTime(2026, 1, 1),
    );
    await controller.markDwelled(const AyahRef(1, 1));
    expect(prefs.getString(ReadingCoverageController.bitsKey), isNull);

    await Future<void>.delayed(const Duration(milliseconds: 40));
    final raw = prefs.getString(ReadingCoverageController.bitsKey);
    expect(raw, isNotNull);
    final restored = KhatamCoverage.fromBytes(base64Decode(raw!));
    expect(restored.markedCount, 1);

    await controller.markDwelled(const AyahRef(1, 1));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final again = KhatamCoverage.fromBytes(
      base64Decode(prefs.getString(ReadingCoverageController.bitsKey)!),
    );
    expect(again.markedCount, 1);
    controller.dispose();
  });

  test('completing a juz shows a celebration without an ask', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = ReadingCoverageController(
      prefs: prefs,
      writeDelay: Duration.zero,
      clock: () => DateTime(2026, 1, 1),
    );
    for (final index in QuranAyahIndex.indexesInJuz(1)) {
      final surah = index < 7 ? 1 : 2;
      final ayah = index < 7 ? index + 1 : index - 6;
      await controller.markDwelled(AyahRef(surah, ayah));
    }
    expect(controller.card, isNotNull);
    expect(controller.card!.milestone.kind, ReadingMilestoneKind.juz);
    expect(controller.card!.askVisible, isFalse);

    await controller.dismissCard();
    expect(controller.card, isNull);
    expect(prefs.getInt(ReadingCoverageController.lastAskKey), isNull);
    controller.dispose();
  });
}
