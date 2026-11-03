// Renders the home widget picker preview ayah (QS 94:5) with the same QPC V2
// page font and WidgetAyahRenderer the live widget uses, and reports size and
// time per bucket. Run with:
//   flutter test tools/widget_ayah_preview_render_test.dart
// Output: android/app/src/main/res/drawable-nodpi/widget_preview_ayah.png
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/widgets/home_widget_ayah_renderer.dart';
import 'package:sqlite3/sqlite3.dart';

const _page = 597;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('render widget preview ayah 94:5', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('QpcV2Page$_page')
        ..addFont(rootBundle.load('assets/fonts/qpc_v2/p$_page.ttf'));
      await loader.load();

      final db = sqlite3.open('assets/mushaf/script/qpc_v2_words.sqlite');
      final words = [
        for (final row in db.select(
          'SELECT text FROM words WHERE surah = 94 AND ayah = 5 ORDER BY word',
        ))
          WidgetGlyphWord(glyph: row['text'] as String, fontFamily: 'QpcV2Page$_page'),
      ];
      db.dispose();

      for (final bucket in WidgetAyahBucket.values) {
        final watch = Stopwatch()..start();
        final png = await WidgetAyahRenderer.renderPng(
          words: words,
          bucket: bucket,
          devicePixelRatio: 3.5,
        );
        watch.stop();
        expect(png, isNotNull);
        // ignore: avoid_print
        print('${bucket.name}: ${png!.lengthInBytes} B, ${watch.elapsedMilliseconds} ms');
        if (bucket == WidgetAyahBucket.medium) {
          File('android/app/src/main/res/drawable-nodpi/widget_preview_ayah.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png);
        }
      }
    });
  });
}
