import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_assets.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_font_loader.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Real QPC V2 pages for golden and geometry tests.
///
/// The page fonts and the layout/words SQLite are bundled data (gitignored,
/// restored with `qo.sh sync`). Tests that need them check
/// [mushafRealPagesAvailable] and skip when the data is missing.
bool get mushafRealPagesAvailable =>
    File(QpcV2Assets.layoutSqlite).existsSync() &&
    File(QpcV2Assets.wordsSqlite).existsSync() &&
    File(QpcV2Assets.pageFontAssetPath(1)).existsSync() &&
    File(QpcV2Assets.pageFontAssetPath(604)).existsSync();

const mushafRealPagesSkipReason =
    'QPC V2 bundled data missing (run scripts/qo.sh sync)';

final Set<String> _loadedFamilies = {};

Future<void> _loadFontFile(String family, String path) async {
  if (_loadedFamilies.contains(family)) return;
  final file = File(path);
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
  _loadedFamilies.add(family);
}

/// Loads the page fonts (as [QpcV2FontLoader] names them), the surah name font,
/// and Roboto from the Flutter SDK cache so UI text renders as real glyphs.
Future<void> loadMushafTestFonts(Iterable<int> pages) async {
  await _loadFontFile('SurahNameV2', 'assets/fonts/surah_name_v2.ttf');
  await _loadFontFile('UthmanicHafsV22', 'assets/fonts/uthmanic_hafs_v22.ttf');
  await _loadFontFile(
    'ScheherazadeNew',
    'assets/fonts/ScheherazadeNew-Regular.ttf',
  );
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    await _loadFontFile(
      'Roboto',
      '$flutterRoot/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
    );
  }
  for (final page in {1, ...pages}) {
    await _loadFontFile(
      QpcV2FontLoader.familyForPage(page),
      QpcV2Assets.pageFontAssetPath(page),
    );
  }
}

Database? _layoutDb;
Database? _wordsDb;

/// Same assembly as `QpcV2Repository._loadPageLines`, read synchronously.
QpcV2PageContent loadRealPage(int pageNumber) {
  final layoutDb = _layoutDb ??=
      sqlite3.open(QpcV2Assets.layoutSqlite, mode: OpenMode.readOnly);
  final wordsDb = _wordsDb ??=
      sqlite3.open(QpcV2Assets.wordsSqlite, mode: OpenMode.readOnly);

  final rows = layoutDb.select(
    'SELECT * FROM pages WHERE page_number = ? ORDER BY line_number',
    [pageNumber],
  );
  int? lastSurahNameId;
  final lines = <QpcV2Line>[];
  for (final row in rows) {
    final lineType = row['line_type'] as String;
    final isCentered = (row['is_centered'] as int? ?? 0) == 1;
    final surahRaw = row['surah_number'];
    final surahId =
        surahRaw is int ? surahRaw : int.tryParse('${surahRaw ?? ''}');
    final lineNumber = row['line_number'] as int;
    if (lineType == 'surah_name') {
      lastSurahNameId = surahId;
      lines.add(QpcV2Line(
        lineNumber: lineNumber,
        lineType: lineType,
        isCentered: isCentered,
        surahId: surahId,
      ));
      continue;
    }
    if (lineType == 'basmallah') {
      lines.add(QpcV2Line(
        lineNumber: lineNumber,
        lineType: lineType,
        isCentered: isCentered,
        surahId: lastSurahNameId,
      ));
      continue;
    }
    if (lineType != 'ayah') continue;
    final first = int.parse('${row['first_word_id']}');
    final last = int.parse('${row['last_word_id']}');
    final words = wordsDb
        .select(
          'SELECT * FROM words WHERE id >= ? AND id <= ? ORDER BY id',
          [first, last],
        )
        .map(
          (w) => QpcV2Word(
            id: w['id'] as int,
            surah: w['surah'] as int,
            ayah: w['ayah'] as int,
            word: w['word'] as int,
            glyph: w['text'] as String,
            location: w['location'] as String,
          ),
        )
        .toList();
    lines.add(QpcV2Line(
      lineNumber: lineNumber,
      lineType: 'ayah',
      isCentered: isCentered,
      words: words,
    ));
  }

  final bismillah = wordsDb
      .select(
        'SELECT text FROM words WHERE id >= ? AND id <= ? ORDER BY id',
        [
          QpcV2Assets.bismillahFirstWordId,
          QpcV2Assets.bismillahStandaloneLastWordId,
        ],
      )
      .map((w) => w['text'] as String)
      .join();

  return QpcV2PageContent(
    pageNumber: pageNumber,
    lines: lines,
    fontFamily: QpcV2FontLoader.familyForPage(pageNumber),
    basmallahFontFamily: QpcV2FontLoader.familyForPage(1),
    bismillahGlyphText: bismillah,
  );
}

/// Bounding box (logical px) of pixels that differ from [background] by more
/// than [threshold] in any channel and are darker/lighter like [ink].
///
/// Used to measure the real line ink of a rendered page.
Future<Rect?> inkBounds(
  WidgetTester tester,
  Finder boundary, {
  required Color ink,
  required Color background,
  int threshold = 90,
  Rect? within,
}) async {
  final render = tester.renderObject<RenderRepaintBoundary>(boundary);
  final image = await tester.runAsync(() => render.toImage(pixelRatio: 1));
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final width = image!.width;
  final height = image.height;
  final bytes = data!.buffer.asUint8List();
  final bg = [
    (background.r * 255).round(),
    (background.g * 255).round(),
    (background.b * 255).round(),
  ];
  final inkC = [
    (ink.r * 255).round(),
    (ink.g * 255).round(),
    (ink.b * 255).round(),
  ];
  final region =
      within ?? Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  var minX = width, minY = height, maxX = -1, maxY = -1;
  for (var y = region.top.floor(); y < region.bottom.ceil(); y++) {
    if (y < 0 || y >= height) continue;
    for (var x = region.left.floor(); x < region.right.ceil(); x++) {
      if (x < 0 || x >= width) continue;
      final i = (y * width + x) * 4;
      var dBg = 0, dInk = 0;
      for (var c = 0; c < 3; c++) {
        dBg += (bytes[i + c] - bg[c]).abs();
        dInk += (bytes[i + c] - inkC[c]).abs();
      }
      // Closer to the ink than to the paper, and clearly not paper.
      if (dBg > threshold && dInk < dBg) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  image.dispose();
  if (maxX < 0) return null;
  return Rect.fromLTRB(
    minX.toDouble(),
    minY.toDouble(),
    maxX + 1.0,
    maxY + 1.0,
  );
}

/// Settings without the notifier's async side effects (notifications plugin,
/// SharedPreferences), for render tests on the host.
class StaticTestSettings extends StateNotifier<AppSettings>
    implements SettingsNotifier {
  StaticTestSettings([AppSettings? settings])
      : super(settings ?? AppSettings(appLanguage: 'id'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Provider overrides for rendering Mushaf pages in tests.
List<Override> mushafRenderOverrides() => [
      settingsProvider.overrideWith((ref) => StaticTestSettings()),
      surahNamesProvider.overrideWith((ref) async => []),
    ];
