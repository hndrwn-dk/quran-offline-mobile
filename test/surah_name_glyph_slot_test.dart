import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';

/// The single-page Mushaf header keeps the exact 1.0.21+69 sizing:
/// a 50% x `clamp(fontSize*1.55, 44, 54)` slot with `BoxFit.fitWidth`.
Future<Size> _pumpLegacyHeader(
  WidgetTester tester, {
  required double pageWidth,
  double mushafFontSize = 38,
  int surahId = 2,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: pageWidth,
            height: 200,
            child: SurahNameMushafGlyph(
              surahId: surahId,
              mushafFontSize: mushafFontSize,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
  return tester.getSize(find.byType(FittedBox));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('SurahNameV2')
      ..addFont(rootBundle.load('assets/fonts/surah_name_v2.ttf'));
    await loader.load();
  });

  testWidgets('single-page header keeps the 69 slot (phone)', (tester) async {
    final slot = await _pumpLegacyHeader(tester, pageWidth: 358);
    expect(slot.width, closeTo(179, 0.01));
    expect(slot.height, closeTo(54, 0.01));
  });

  testWidgets('single-page header keeps the 69 slot on every width',
      (tester) async {
    for (final pageWidth in [358.0, 370.0, 432.0, 400.0]) {
      final slot = await _pumpLegacyHeader(tester, pageWidth: pageWidth);
      expect(slot.width, closeTo(pageWidth * 0.5, 0.01));
      expect(slot.height, closeTo(54, 0.01));
    }
  });

  testWidgets('small header font uses the 44dp clamp', (tester) async {
    final slot = await _pumpLegacyHeader(
      tester,
      pageWidth: 358,
      mushafFontSize: 28,
    );
    expect(slot.height, closeTo(44, 0.01));
  });

  testWidgets('surah 33 uses the font short ligature', (tester) async {
    expect(SurahNameGlyph.ligatureFor(33), '033');
    await _pumpLegacyHeader(tester, pageWidth: 358, surahId: 33);
    expect(tester.takeException(), isNull);
  });
}
