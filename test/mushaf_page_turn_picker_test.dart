import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_turn_picker.dart';
import 'package:quran_offline/features/settings/widgets/settings_sections.dart';

import 'support/mushaf_real_pages.dart';

/// The page-turn picker at its narrowest: Settings on a 360dp phone, at the
/// default and a large (1.3) font scale, in every app language. Labels must
/// never be cut off or overflow.
///
/// `PICKER_SHOTS=<dir>` also writes a PNG per case for a visual check.
void main() {
  final shots = Platform.environment['PICKER_SHOTS'];

  setUpAll(() async => loadMushafTestFonts(const []));

  for (final language in const ['id', 'en', 'zh', 'ja']) {
    for (final scale in const [1.0, 1.3]) {
      for (final turn in MushafPageTurn.values) {
        final name = 'settings_360_${language}_x${scale}_${turn.name}';
        testWidgets(name, (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final key = GlobalKey();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                settingsProvider.overrideWith(
                  (ref) => StaticTestSettings(
                    AppSettings(appLanguage: language, mushafPageTurn: turn),
                  ),
                ),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  colorScheme: AppColors.lightColorScheme(),
                  fontFamily: 'Roboto',
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: child!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: RepaintBoundary(
                      key: key,
                      child: Material(
                        color: AppColors.lightColorScheme().surface,
                        child: const SettingsQuranSection(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'overflow in $name');

          final picker = find.byType(MushafPageTurnPicker);
          await tester.ensureVisible(picker);
          await tester.pumpAndSettle();
          for (final key in const [
            'page_turn_curl',
            'page_turn_slide',
            'page_turn_none',
          ]) {
            final label = AppLocalizations.getSettingsText(key, language);
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: picker, matching: find.text(label)),
            );
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: '"$label" is cut off in $name',
            );
            // No word may be broken across lines ("Langsun|g").
            for (final word in label.split(' ')) {
              final painter = TextPainter(
                text: TextSpan(text: word, style: paragraph.text.style),
                textDirection: TextDirection.ltr,
                textScaler: paragraph.textScaler,
              )..layout();
              expect(
                painter.width,
                lessThanOrEqualTo(paragraph.size.width + 0.5),
                reason: '"$word" is split in $name',
              );
              painter.dispose();
            }
          }
          final hint = AppLocalizations.getSettingsText(
            'page_turn_hint_${turn.name}',
            language,
          );
          expect(find.text(hint), findsOneWidget);

          if (shots != null) {
            final boundary =
                key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final bytes = await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 2);
              final data =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              image.dispose();
              return data!.buffer.asUint8List();
            });
            Directory(shots).createSync(recursive: true);
            File('$shots/$name.png').writeAsBytesSync(bytes!);
          }
        });
      }
    }
  }

  testWidgets('picking an option reports it and swaps the hint', (t) async {
    var value = MushafPageTurn.slide;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MushafPageTurnPicker(
              value: value,
              language: 'id',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Halaman bergeser ke samping.'), findsOneWidget);
    await t.tap(find.text('Seperti buku'));
    await t.pumpAndSettle();
    expect(value, MushafPageTurn.curl);
    expect(
      find.text(
        'Halaman melengkung dan dibalik seperti mushaf cetak. '
        'Paling pas di HP lipat dan tablet.',
      ),
      findsOneWidget,
    );
    await t.tap(find.text('Langsung'));
    await t.pumpAndSettle();
    expect(value, MushafPageTurn.none);
    expect(find.text('Halaman langsung berganti tanpa animasi.'), findsOneWidget);
  });
}
