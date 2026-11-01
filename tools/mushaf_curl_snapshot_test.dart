// Renders the interactive leaf turn at a few progress values with real QPC
// content, for visual verification of the curl painter (not a strict golden).
//
//   flutter test tools/mushaf_curl_snapshot_test.dart
//
// Writes PNGs to GOLDEN_DIR (default build/mushaf_curls).
// This file is not part of the normal `test/` suite.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_painter.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_curl_shader.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

const _layoutDb = 'assets/mushaf/layout/qpc_v2_15_lines.sqlite';
const _wordsDb = 'assets/mushaf/script/qpc_v2_words.sqlite';
const _progressValues = [0.0, 0.25, 0.5, 0.75, 1.0];
const _pages = [1, 2, 3, 4];

Future<void> _loadFonts() async {
  final surah = FontLoader('SurahNameV2')
    ..addFont(rootBundle.load('assets/fonts/surah_name_v2.ttf'));
  await surah.load();
  for (final page in _pages) {
    final loader = FontLoader('QpcV2Page$page')
      ..addFont(rootBundle.load('assets/fonts/qpc_v2/p$page.ttf'));
    await loader.load();
  }
}

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is String && v.isNotEmpty) return int.tryParse(v);
  return null;
}

QpcV2PageContent _loadPage(int pageNumber) {
  final layout = sqlite3.open(_layoutDb, mode: OpenMode.readOnly);
  final wordsDb = sqlite3.open(_wordsDb, mode: OpenMode.readOnly);
  try {
    final rows = layout.select(
      'SELECT * FROM pages WHERE page_number = ? ORDER BY line_number ASC',
      [pageNumber],
    );
    int? lastSurahId;
    final ranges = <({int line, bool centered, int first, int last})>[];
    final lines = <QpcV2Line>[];
    for (final row in rows) {
      final type = row['line_type'] as String;
      final centered = (row['is_centered'] as int? ?? 0) == 1;
      final surahId = _asInt(row['surah_number']);
      if (type == 'surah_name') {
        lastSurahId = surahId;
        lines.add(QpcV2Line(
          lineNumber: row['line_number'] as int,
          lineType: type,
          isCentered: centered,
          surahId: surahId,
        ));
        continue;
      }
      if (type == 'basmallah') {
        lines.add(QpcV2Line(
          lineNumber: row['line_number'] as int,
          lineType: type,
          isCentered: centered,
          surahId: lastSurahId,
        ));
        continue;
      }
      if (type != 'ayah') continue;
      final first = _asInt(row['first_word_id']);
      final last = _asInt(row['last_word_id']);
      if (first == null || last == null) continue;
      ranges.add((
        line: row['line_number'] as int,
        centered: centered,
        first: first,
        last: last,
      ));
    }
    if (ranges.isNotEmpty) {
      final minId = ranges.map((r) => r.first).reduce((a, b) => a < b ? a : b);
      final maxId = ranges.map((r) => r.last).reduce((a, b) => a > b ? a : b);
      final wordRows = wordsDb.select(
        'SELECT id, surah, ayah, word, text, location FROM words '
        'WHERE id BETWEEN ? AND ? ORDER BY id ASC',
        [minId, maxId],
      );
      final byId = <int, QpcV2Word>{
        for (final w in wordRows)
          w['id'] as int: QpcV2Word(
            id: w['id'] as int,
            surah: w['surah'] as int,
            ayah: w['ayah'] as int,
            word: w['word'] as int,
            glyph: w['text'] as String,
            location: w['location'] as String,
          ),
      };
      for (final r in ranges) {
        final words = <QpcV2Word>[];
        for (var id = r.first; id <= r.last; id++) {
          final w = byId[id];
          if (w != null) words.add(w);
        }
        lines.add(QpcV2Line(
          lineNumber: r.line,
          lineType: 'ayah',
          isCentered: r.centered,
          words: words,
        ));
      }
    }
    lines.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));
    final bismillah = wordsDb
        .select('SELECT text FROM words WHERE id BETWEEN 1 AND 4 ORDER BY id')
        .map((r) => r['text'] as String)
        .join();
    return QpcV2PageContent(
      pageNumber: pageNumber,
      lines: lines,
      fontFamily: 'QpcV2Page$pageNumber',
      basmallahFontFamily: 'QpcV2Page1',
      bismillahGlyphText: bismillah,
    );
  } finally {
    layout.dispose();
    wordsDb.dispose();
  }
}

/// Renders one page sheet at [size] and returns its pixels.
Future<ui.Image> _renderPage(
  WidgetTester tester,
  int pageNo,
  Size size,
  ColorScheme scheme,
) async {
  final key = GlobalKey();
  // Mutable on purpose: the glyph renderer registers an ayah key per line.
  final ayahKeys = <String, GlobalKey>{};
  final fullContent = _loadPage(pageNo);
  final content = QpcV2PageContent(
    pageNumber: fullContent.pageNumber,
    // Header/basmallah rows pull in app services; the curl only needs glyph ink.
    lines: fullContent.lines.where((line) => line.isAyah).toList(),
    fontFamily: fullContent.fontFamily,
    basmallahFontFamily: fullContent.basmallahFontFamily,
    bismillahGlyphText: fullContent.bismillahGlyphText,
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true, colorScheme: scheme),
        home: Scaffold(
          backgroundColor: scheme.surface,
          body: Center(
            child: RepaintBoundary(
              key: key,
              // The app's page boundary wraps an opaque ColoredBox, so the
              // snapshot is paper, not transparent glyphs.
              child: ColoredBox(
                color: scheme.surface,
                child: SizedBox.fromSize(
                  size: size,
                  child: MushafPageSheet(
                    content: content,
                    colorScheme: scheme,
                    ayahKeys: ayahKeys,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  return image!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mushaf curl snapshots', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (call) async => call.method == 'init' ? null : <String, dynamic>{},
    );
    await _loadFonts();
    final shader = await loadPageCurlShader();
    final outDir = Directory(
      Platform.environment['GOLDEN_DIR'] ?? 'build/mushaf_curls',
    );
    outDir.createSync(recursive: true);

    for (final (size, spread) in const [
      (Size(933, 704), true),
      (Size(390, 844), false),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final brightness in Brightness.values) {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F6B4A),
          brightness: brightness,
        );
        final background = scheme.surface;

        final Rect leftRect;
        final Rect rightRect;
        if (spread) {
          final page = mushafPageFrameSize(
            Size((size.width - 32 - kMushafSpreadGap) / 2, size.height - 32),
          );
          final originX = (size.width - page.width * 2 - kMushafSpreadGap) / 2;
          final originY = (size.height - page.height) / 2;
          leftRect = Rect.fromLTWH(originX, originY, page.width, page.height);
          rightRect = Rect.fromLTWH(
            originX + page.width + kMushafSpreadGap,
            originY,
            page.width,
            page.height,
          );
        } else {
          final page = mushafPageFrameSize(
            Size(size.width - 32, size.height - 32),
          );
          leftRect = Rect.fromLTWH(
            (size.width - page.width) / 2,
            (size.height - page.height) / 2,
            page.width,
            page.height,
          );
          rightRect = leftRect;
        }

        final images = <int, ui.Image>{};
        for (final page in _pages) {
          images[page] = await _renderPage(tester, page, leftRect.size, scheme);
        }

        for (final progress in _progressValues) {
          // Forward turn from 1|2: leaf 2, back 3, revealed 4, stationary 1.
          final geometry = spread
              ? PageTurnGeometry.spread(
                  leftRect: leftRect,
                  rightRect: rightRect,
                  hingeGap: kMushafSpreadGap,
                  direction: PageTurnDirection.forward,
                  progress: progress,
                )
              : PageTurnGeometry.single(
                  pageRect: leftRect,
                  direction: PageTurnDirection.forward,
                  progress: progress,
                );
          final below = spread
              ? [
                  PageTurnBelowPage(rect: leftRect, image: images[4]),
                  PageTurnBelowPage(rect: rightRect, image: images[1]),
                ]
              : [PageTurnBelowPage(rect: leftRect, image: images[2])];

          final key = GlobalKey();
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: ThemeData(useMaterial3: true, colorScheme: scheme),
                home: Scaffold(
                  backgroundColor: background,
                  body: RepaintBoundary(
                    key: key,
                    child: SizedBox.expand(
                      child: CustomPaint(
                        painter: PageCurlPainter(
                          geometry: geometry,
                          background: background,
                          ink: scheme.onSurface,
                          frontImage: images[spread ? 2 : 1],
                          backImage: images[spread ? 3 : 2],
                          belowPages: below,
                          tilt: 0.35,
                          shader: shader,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image =
              await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
          final data = await tester.runAsync(
            () => image!.toByteData(format: ui.ImageByteFormat.png),
          );
          final pct = (progress * 100).round();
          final suffix = brightness == Brightness.dark ? 'dark' : 'light';
          File(
            '${outDir.path}/curl_p$pct'
            '_${size.width.toInt()}x${size.height.toInt()}_$suffix.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image!.dispose();

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        }
        for (final image in images.values) {
          image.dispose();
        }
      }
    }
    while (tester.takeException() != null) {}
  });
}
