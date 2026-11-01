import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_number_badge.dart';
import 'package:quran_offline/features/read/widgets/qpc_v2_mushaf_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/mushaf_real_pages.dart';

/// < 600dp (phone, Fold cover) Mushaf: the flowing glyph text path and the
/// floating page badge, at the Pixel and Fold cover window sizes.
///
/// Regenerate only with explicit approval:
///   flutter test --update-goldens test/mushaf_phone_golden_test.dart
/// `PHONE_GOLDEN_DIR` renders into another folder (before/after comparisons).
void main() {
  const pages = [1, 2, 3, 50, 585, 587, 588, 595, 603, 604];
  final dir = Platform.environment['PHONE_GOLDEN_DIR'] ?? 'goldens/phone';

  setUpAll(() async {
    if (mushafRealPagesAvailable) await loadMushafTestFonts(pages);
  });
  setUp(() => SharedPreferences.setMockInitialValues({'appLanguage': 'id'}));

  for (final size in const [Size(390, 844), Size(475, 751)]) {
    for (final dark in const [false, true]) {
      final themeName = dark ? 'dark' : 'light';
      for (final pageNo in pages) {
        final name = 'phone_${size.width.round()}x${size.height.round()}'
            '_p${pageNo}_$themeName';
        testWidgets(name, (tester) async {
          tester.view.physicalSize = size;
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
            matchesGoldenFile('$dir/$name.png'),
          );
        }, skip: !mushafRealPagesAvailable);
      }
    }
  }
}
