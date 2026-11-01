// Renders the two-page spread with real QPC content, for visual verification.
//
//   flutter test tools/mushaf_spread_snapshot_test.dart
//
// Writes PNGs to GOLDEN_DIR (default build/mushaf_spreads).
// This file is not part of the normal `test/` suite.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/mushaf/surah_name_ink_layout.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_number_badge.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_sheet.dart';
import 'package:sqlite3/sqlite3.dart';

const _layoutDb = 'assets/mushaf/layout/qpc_v2_15_lines.sqlite';
const _wordsDb = 'assets/mushaf/script/qpc_v2_words.sqlite';
const _spreads = [1, 49, 601, 603];

Future<void> _loadFonts() async {
  final surah = FontLoader('SurahNameV2')
    ..addFont(rootBundle.load('assets/fonts/surah_name_v2.ttf'));
  await surah.load();
  for (final page in {1, 2, 49, 50, 603, 604}) {
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

Widget _spread(int oddPage, int evenPage, ColorScheme scheme, {MushafSpineStyle spine = MushafSpineStyle.softShade}) {
  final hinge = const MushafHingeLayout();
  final leftContent = _loadPage(evenPage);
  final rightContent = _loadPage(oddPage);
  double openingScale = 1;
  if (oddPage <= 2) {
    final lines = [leftContent, rightContent].expand(
      (page) => page.lines
          .where((line) => line.isAyah && line.glyphText.isNotEmpty)
          .map((line) => (
                glyphText: line.glyphText,
                fontFamily: page.fontFamily,
                justify: false,
              )),
    );
    openingScale = computeOpeningPageScale(lines: lines);
    debugPrint('[OpeningScale] pages $oddPage|$evenPage -> $openingScale');
  }
  return Column(
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: MushafSpreadRow(
            hinge: hinge,
            spine: spine,
            left: MushafPageSheet(
              content: leftContent,
              openingPageScale: openingScale,
              colorScheme: scheme,
              ayahKeys: <String, GlobalKey>{},
            ),
            right: MushafPageSheet(
              content: rightContent,
              openingPageScale: openingScale,
              colorScheme: scheme,
              ayahKeys: <String, GlobalKey>{},
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: MushafPageNumberBadge(
          pageNo: oddPage,
          rangeEnd: evenPage,
        ),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mushaf spread snapshots', (tester) async {
    await _loadFonts();
    final outDir = Directory(
      Platform.environment['GOLDEN_DIR'] ?? 'build/mushaf_spreads',
    );
    outDir.createSync(recursive: true);
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3F6B4A));

    tester.view.physicalSize = const Size(933, 704);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final odd in _spreads) {
      final even = odd + 1;
      for (final (suffix, spine) in [
        ('', MushafSpineStyle.softShade),
        if (odd == 1) ('_nospine', MushafSpineStyle.none),
      ]) {
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: ThemeData(useMaterial3: true, colorScheme: scheme),
              home: Scaffold(
                body: RepaintBoundary(
                  key: key,
                  child: _spread(odd, even, scheme, spine: spine),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
        final data = await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.png),
        );
        File('${outDir.path}/spread_${odd}_${even}_933x704$suffix.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
        image!.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
    while (tester.takeException() != null) {}
  });
}


