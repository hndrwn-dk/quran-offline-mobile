// Snapshot harness used to prove single-page Mushaf rendering is unchanged
// against tag v1.0.21+69.
//
// Renders the exact single-page body primitives (flow QpcV2MushafText +
// SurahNameMushafGlyph + page badge) with real page content from the bundled
// QPC V2 layout DB, then writes one PNG per page/size.
//
// Run on both branches:
//   flutter test tools/mushaf_render_snapshot_test.dart
// with GOLDEN_DIR=<folder> to choose the output folder.
//
// This file is intentionally not part of the normal `test/` suite.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_number_badge.dart';
import 'package:quran_offline/features/read/widgets/qpc_v2_mushaf_text.dart';
import 'package:sqlite3/sqlite3.dart';

const _layoutDb = 'assets/mushaf/layout/qpc_v2_15_lines.sqlite';
const _wordsDb = 'assets/mushaf/script/qpc_v2_words.sqlite';
const _pages = [1, 2, 3, 50, 187, 418, 604];
const _sizes = [Size(390, 844), Size(475, 751)];

Future<void> _loadFonts(Iterable<int> pageNumbers) async {
  final surah = FontLoader('SurahNameV2')
    ..addFont(rootBundle.load('assets/fonts/surah_name_v2.ttf'));
  await surah.load();
  for (final page in {...pageNumbers, 1}) {
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

QpcV2PageContent _loadPage(int pageNumber) {
  final layout = sqlite3.open(_layoutDb, mode: OpenMode.readOnly);
  final wordsDb = sqlite3.open(_wordsDb, mode: OpenMode.readOnly);
  try {
    final rows = layout.select(
      'SELECT * FROM pages WHERE page_number = ? ORDER BY line_number ASC',
      [pageNumber],
    );
    int? lastSurahId;
    final ayahRanges =
        <({int lineNumber, bool centered, int first, int last})>[];
    final lines = <QpcV2Line>[];

    for (final row in rows) {
      final type = row['line_type'] as String;
      final centered = (row['is_centered'] as int? ?? 0) == 1;
      final surahId = _asInt(row['surah_number']);

      if (type == 'surah_name') {
        lastSurahId = surahId;
        lines.add(
          QpcV2Line(
            lineNumber: row['line_number'] as int,
            lineType: type,
            isCentered: centered,
            surahId: surahId,
          ),
        );
        continue;
      }
      if (type == 'basmallah') {
        lines.add(
          QpcV2Line(
            lineNumber: row['line_number'] as int,
            lineType: type,
            isCentered: centered,
            surahId: lastSurahId,
          ),
        );
        continue;
      }
      if (type != 'ayah') continue;
      final first = _asInt(row['first_word_id']);
      final last = _asInt(row['last_word_id']);
      if (first == null || last == null) continue;
      ayahRanges.add((
        lineNumber: row['line_number'] as int,
        centered: centered,
        first: first,
        last: last,
      ));
    }

    if (ayahRanges.isNotEmpty) {
      final minId = ayahRanges.map((r) => r.first).reduce((a, b) => a < b ? a : b);
      final maxId = ayahRanges.map((r) => r.last).reduce((a, b) => a > b ? a : b);
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
      for (final range in ayahRanges) {
        final words = <QpcV2Word>[];
        for (var id = range.first; id <= range.last; id++) {
          final word = byId[id];
          if (word != null) words.add(word);
        }
        lines.add(
          QpcV2Line(
            lineNumber: range.lineNumber,
            lineType: 'ayah',
            isCentered: range.centered,
            words: words,
          ),
        );
      }
    }
    lines.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));

    final bismillahRows = wordsDb.select(
      'SELECT text FROM words WHERE id BETWEEN 1 AND 4 ORDER BY id ASC',
    );
    final bismillah =
        bismillahRows.map((r) => r['text'] as String).join();

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

Widget _pageBody(
  QpcV2PageContent content,
  int pageNo,
  ColorScheme scheme,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => QpcV2MushafText(
                    content: content,
                    contentWidth: constraints.maxWidth,
                    fontSize: 38,
                    colorScheme: scheme,
                    ayahKeys: <String, GlobalKey>{},
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        Center(child: MushafPageNumberBadge(pageNo: pageNo)),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mushaf single-page snapshots', (tester) async {
    final pages = (Platform.environment['PAGES'] ?? _pages.join(','))
        .split(',')
        .map(int.parse)
        .toList();
    await _loadFonts(pages);

    final outDir = Directory(
      Platform.environment['GOLDEN_DIR'] ?? 'build/mushaf_snapshots',
    );
    outDir.createSync(recursive: true);

    final headerRects = <String, List<List<double>>>{};

    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3F6B4A));

    final envSizes = (Platform.environment['SIZES'] ?? '')
        .split(',')
        .where((value) => value.isNotEmpty)
        .map((value) {
      final parts = value.split('x');
      return Size(double.parse(parts[0]), double.parse(parts[1]));
    }).toList();
    final sizes = envSizes.isEmpty ? _sizes : envSizes;

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final page in pages) {
        debugPrint('snapshot page $page at $size');
        final content = _loadPage(page);
        debugPrint('content loaded: ${content.lines.length} lines');
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true, colorScheme: scheme),
              home: Scaffold(
                body: RepaintBoundary(
                  key: key,
                  child: _pageBody(content, page, scheme),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await tester.runAsync(
          () => boundary.toImage(pixelRatio: 1),
        );
        final data = await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.png),
        );
        final file = File(
          '${outDir.path}/p${page}_${size.width.toInt()}x${size.height.toInt()}.png',
        );
        file.writeAsBytesSync(data!.buffer.asUint8List());
        image!.dispose();

        final headers = find.byType(SurahNameMushafFlowHeader);
        final rectKey = 'p${page}_${size.width.toInt()}x${size.height.toInt()}';
        headerRects[rectKey] = [
          for (var i = 0; i < headers.evaluate().length; i++)
            () {
              final r = tester.getRect(headers.at(i));
              return [r.left, r.top, r.right, r.bottom];
            }(),
        ];

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }

    // The page renderers watch the recitation provider; platform channels are
    // not available in this harness, so drain those non-fatal errors.
    while (tester.takeException() != null) {}

    File('${outDir.path}/header_rects.json').writeAsStringSync(
      jsonEncode(headerRects),
    );
  });
}







