import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/quran_fonts.dart';
import 'package:quran_offline/core/widgets/quran_arabic_text.dart';

void main() {
  test('arabicDisplayStyle defaults to DigitalKhattV2', () {
    final style = QuranArabicText.arabicDisplayStyle(
      fontSize: 24,
      color: Colors.black,
    );
    expect(style.fontFamily, QuranFonts.digitalKhattV2);
    expect(style.fontFamilyFallback, QuranFonts.digitalKhattFallbacks);
  });

  test('arabicDisplayStyle can still request UthmanicHafsV22', () {
    final style = QuranArabicText.arabicDisplayStyle(
      fontSize: 24,
      color: Colors.black,
      fontFamily: QuranFonts.uthmanicHafsV22,
    );
    expect(style.fontFamily, QuranFonts.uthmanicHafsV22);
    expect(style.fontFamilyFallback, QuranFonts.uthmanicFallbacks);
  });

  testWidgets('QuranArabicText default family is DigitalKhattV2', (tester) async {
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
    expect(selectable.style?.fontFamily, QuranFonts.digitalKhattV2);
  });
}
