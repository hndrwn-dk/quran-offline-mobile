// Real QPC V2 pages must rasterize with ink before a curl may use them.
//
// This is the regression test for the device bug where the turning leaf and the
// page underneath were blank paper: a snapshot captured from a boundary that
// never painted (or painted before its per-page font was ready) is flat paper.
// It renders the real page widget with the real bundled fonts/SQLite data and
// asserts the captured pixels carry ink.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/page_turn/page_turn_snapshots.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

const _layoutDb = 'assets/mushaf/layout/qpc_v2_15_lines.sqlite';
const _wordsDb = 'assets/mushaf/script/qpc_v2_words.sqlite';
const _testPages = [1, 2, 3, 4, 50, 603, 604];

Future<void> _loadFonts() async {
  final surah = FontLoader('SurahNameV2')
    ..addFont(rootBundle.load('assets/fonts/surah_name_v2.ttf'));
  await surah.load();
  for (final page in _testPages) {
    final loader = FontLoader('QpcV2Page$page')
      ..addFont(rootBundle.load('assets/fonts/qpc_v2/p$page.ttf'));
    await loader.load();
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is String && value.isNotEmpty) return int.tryParse(value);
  return null;
}

/// Mirrors the layout loader the reader uses, but reads the bundled SQLite
/// directly so the test does not need the sqflite plugin.
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
          final word = byId[id];
          if (word != null) words.add(word);
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The page widgets watch the recitation player for highlighting. There is
    // no audio platform in a widget test; make its init/dispose complete so the
    // idle player can be torn down cleanly.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (call) async {
        if (call.method == 'init') return null;
        return <String, dynamic>{};
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      null,
    );
  });

  testWidgets('captured pages 1,2,3,4,50,603,604 are not blank',
      (tester) async {
    await _loadFonts();
    const dpr = 2.0;
    final pageSize = mushafPageFrameSize(
      const Size((933 - 32 - kMushafSpreadGap) / 2, 704 - 32),
    );
    // Logical 933x704 at 2x, so the captured image is pageSize * dpr.
    tester.view.physicalSize = const Size(1866, 1408);
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);

    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3F6B4A));
    for (final pageNo in _testPages) {
      final rawContent = _loadPage(pageNo);
      // Keep the real glyph rows only: the surah header and basmallah widgets
      // pull in notification/audio app services that a paint test does not
      // need. The ink this test cares about is the QPC glyph text.
      final content = QpcV2PageContent(
        pageNumber: rawContent.pageNumber,
        lines: rawContent.lines.where((line) => line.isAyah).toList(),
        fontFamily: rawContent.fontFamily,
        basmallahFontFamily: rawContent.basmallahFontFamily,
        bismillahGlyphText: rawContent.bismillahGlyphText,
      );
      final ayahKeys = <String, GlobalKey>{};
      double openingScale = 1;
      if (pageNo <= 2) {
        final sibling = _loadPage(pageNo == 1 ? 2 : 1);
        final glyphLines = [content, sibling].expand(
          (page) => page.lines
              .where((line) => line.isAyah && line.glyphText.isNotEmpty)
              .map((line) => (
                    glyphText: line.glyphText,
                    fontFamily: page.fontFamily,
                    justify: false,
                  )),
        );
        openingScale = computeOpeningPageScale(lines: glyphLines);
      }

      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true, colorScheme: scheme),
            home: Scaffold(
              backgroundColor: scheme.surface,
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  // Same wrapping as the reader: the boundary owns an opaque
                  // paper layer, so a transparent glyph layer is impossible.
                  child: ColoredBox(
                    color: scheme.surface,
                    child: SizedBox.fromSize(
                      size: pageSize,
                      child: MushafPageSheet(
                        content: content,
                        openingPageScale: openingScale,
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
      // One frame to build, one to paint the glyphs with their loaded font.
      await tester.pump();
      await tester.pump();

      expect(
        snapshotBoundaryIsPainted(key),
        isTrue,
        reason: 'page $pageNo boundary must have painted',
      );

      final image = await tester.runAsync(() async {
        return capturePageSnapshotFor(key, pixelRatio: dpr);
      });
      expect(image, isNotNull, reason: 'page $pageNo snapshot');
      expect(image!.width, closeTo(pageSize.width * dpr, 2));
      expect(image.height, closeTo(pageSize.height * dpr, 2));

      final coverage = await tester.runAsync(() => imageInkCoverage(image));
      expect(
        coverage,
        greaterThan(kPageTurnMinInkCoverage),
        reason: 'page $pageNo captured blank paper (coverage $coverage)',
      );
      image.dispose();
      // Keep the same ProviderScope alive between pages: tearing it down while
      // the idle audio player is still initializing races just_audio's streams.
    }
    while (tester.takeException() != null) {}
  });

  testWidgets('ink check rejects flat paper and accepts a painted page',
      (tester) async {
    final blank = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 400, 600),
        Paint()..color = const Color(0xFFF7F3E8),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(400, 600);
      picture.dispose();
      return image;
    });
    expect(blank, isNotNull);
    final blankImage = blank!;
    final blankCoverage =
        await tester.runAsync(() => imageInkCoverage(blankImage));
    expect(blankCoverage, lessThan(kPageTurnMinInkCoverage));
    expect(
      await tester.runAsync(() => imageHasInk(blankImage)),
      isFalse,
    );
    blankImage.dispose();
  });
}
