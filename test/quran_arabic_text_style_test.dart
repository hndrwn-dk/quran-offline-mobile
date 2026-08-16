import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/quran_fonts.dart';
import 'package:quran_offline/core/widgets/quran_arabic_text.dart';

void main() {
  test('share/mushaf arabicDisplayStyle stays UthmanicHafsV22', () {
    final style = QuranArabicText.arabicDisplayStyle(
      fontSize: 24,
      color: Colors.black,
    );
    expect(style.fontFamily, QuranFonts.uthmanicHafsV22);
    expect(style.fontFamily, isNot(QuranFonts.digitalKhattV2));
  });

  testWidgets('QuranArabicText default family is UthmanicHafsV22', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuranArabicText(
            arabic: 'بِسْمِ',
            fontSize: 24,
            defaultColor: Colors.black,
          ),
        ),
      ),
    );
    final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(selectable.style?.fontFamily, QuranFonts.uthmanicHafsV22);
  });

  testWidgets('QuranArabicText fontFamily override uses DigitalKhattV2', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuranArabicText(
            arabic: 'بِسْمِ',
            fontSize: 24,
            defaultColor: Colors.black,
            fontFamily: QuranFonts.digitalKhattV2,
          ),
        ),
      ),
    );
    final selectable = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(selectable.style?.fontFamily, QuranFonts.digitalKhattV2);
  });
}
