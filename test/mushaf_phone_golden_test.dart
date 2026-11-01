import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_number_badge.dart';
import 'package:quran_offline/features/read/widgets/qpc_v2_mushaf_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/mushaf_real_pages.dart';

/// < 600dp (phone, Fold cover) Mushaf must stay pixel-identical: the flowing
/// glyph text path and the floating page badge.
///
/// Regenerate only with explicit approval:
///   flutter test --update-goldens test/mushaf_phone_golden_test.dart
void main() {
  const pages = [1, 3, 603];
  setUpAll(() async {
    if (mushafRealPagesAvailable) await loadMushafTestFonts(pages);
  });
  setUp(() => SharedPreferences.setMockInitialValues({'appLanguage': 'id'}));

  for (final width in const [390.0, 475.0]) {
    for (final dark in const [false, true]) {
      final themeName = dark ? 'dark' : 'light';
      for (final pageNo in pages) {
        testWidgets('phone ${width.round()}dp page $pageNo $themeName',
            (tester) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final scheme =
              dark ? AppColors.darkColorScheme() : AppColors.lightColorScheme();
          final content = loadRealPage(pageNo);
          await tester.pumpWidget(
            ProviderScope(
              overrides: mushafRenderOverrides(),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(colorScheme: scheme, fontFamily: 'Roboto'),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      // MushafPageBody flow padding.
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) => QpcV2MushafText(
                              content: content,
                              contentWidth: constraints.maxWidth,
                              fontSize: 38,
                              colorScheme: scheme,
                              ayahKeys: Map<String, GlobalKey>.of(const {}),
                            ),
                          ),
                          MushafPageNumberBadge(pageNo: pageNo),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
              'goldens/phone/phone_${width.round()}_p${pageNo}_$themeName.png',
            ),
          );
        }, skip: !mushafRealPagesAvailable);
      }
    }
  }
}
