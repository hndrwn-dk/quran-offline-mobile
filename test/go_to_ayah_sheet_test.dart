import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/features/reader/widgets/go_to_ayah_sheet.dart';

void main() {
  test('buildGoToAyahShortcuts includes Kursi for surah 2', () {
    final shortcuts = buildGoToAyahShortcuts(
      language: 'id',
      surahId: 2,
      verseCount: 286,
    );
    expect(
      shortcuts.any((s) => s.ayahNo == kAyatKursiAyahNo),
      isTrue,
    );
  });

  test('buildGoToAyahShortcuts omits Kursi for other surahs', () {
    final shortcuts = buildGoToAyahShortcuts(
      language: 'en',
      surahId: 1,
      verseCount: 7,
    );
    expect(
      shortcuts.any((s) => s.ayahNo == kAyatKursiAyahNo),
      isFalse,
    );
    expect(shortcuts.first.ayahNo, 1);
    expect(shortcuts.last.ayahNo, 7);
  });
}
