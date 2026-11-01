// Renders the option-I surah-header cartouche for visual checks.
// flutter test tools/mushaf_surah_header_snapshot_test.dart
// Writes PNGs to GOLDEN_DIR (default build/cartouche).

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/surah_name_ink_layout.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';

const _surahs = [1, 2, 9, 110, 105, 114];

ThemeData _theme(String name) {
  switch (name) {
    case 'dark':
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F6B4A),
          brightness: Brightness.dark,
        ),
      );
    case 'sepia':
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A5C3A),
          brightness: Brightness.light,
        ).copyWith(surface: const Color(0xFFF4ECD8)),
      );
    default:
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F6B4A),
        ),
      );
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  File(path).writeAsBytesSync(data!.buffer.asUint8List());
  image!.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cartouche strips', (tester) async {
    final loader = FontLoader('SurahNameV2')
      ..addFont(rootBundle.load('assets/fonts/surah_name_v2.ttf'));
    await loader.load();

    final outDir = Directory(
      Platform.environment['GOLDEN_DIR'] ?? 'build/cartouche',
    );
    outDir.createSync(recursive: true);

    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final themeName in ['light', 'dark', 'sepia']) {
      final theme = _theme(themeName);
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            surahNamesProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            theme: theme,
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: Container(
                  color: theme.colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final surah in _surahs)
                        SizedBox(
                          width: 390,
                          child: SurahNameMushafFlowHeader(
                            surahId: surah,
                            mushafFontSize: 38,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await _capture(tester, key, '${outDir.path}/phone_$themeName.png');
    }

    // Framed header (spread scale) strip.
    final framedKey = GlobalKey();
    final theme = _theme('light');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahNamesProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            body: RepaintBoundary(
              key: framedKey,
              child: Center(
                child: SizedBox(
                  width: kMushafPageLayoutWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final surah in _surahs)
                        SizedBox(
                          height: kMushafPageRowHeight,
                          child: SurahNameMushafInkGlyph(
                            surahId: surah,
                            color: theme.colorScheme.onSurface,
                            targetInkHeight: kMushafPageRowHeight *
                                kSurahNameInkHeightFactor,
                            maxInkWidth: kMushafPageLayoutWidth *
                                kSurahNameMaxInkWidthFactor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await _capture(tester, framedKey, '${outDir.path}/framed_light.png');

    while (tester.takeException() != null) {}
  });
}
