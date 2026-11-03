import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_font_loader.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_mushaf_layout.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_repository.dart';

/// Widget size bucket that shows the Arabic ayah (the small one does not).
enum WidgetAyahBucket {
  medium(key: 'widget_ayah_m', logicalWidth: 300, logicalHeight: 60, maxLines: 2),
  large(key: 'widget_ayah_l', logicalWidth: 300, logicalHeight: 104, maxLines: 3);

  const WidgetAyahBucket({
    required this.key,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.maxLines,
  });

  /// home_widget storage key: the PNG lands at `home_widget/<key>.png`.
  final String key;
  final double logicalWidth;
  final double logicalHeight;
  final int maxLines;

  String get signatureKey => '${key}_sig';
}

/// One QPC V2 glyph word plus the per-page font family that draws it.
class WidgetGlyphWord {
  const WidgetGlyphWord({required this.glyph, required this.fontFamily});

  final String glyph;
  final String fontFamily;
}

/// Line packing in reading order. Returns word indices per line; a word wider
/// than [maxWidth] still gets a line of its own. Keeps the greedy line count
/// but evens the line widths, and the last glyph (the ayah-end marker) never
/// stands alone: the word before it moves down with it.
List<List<int>> packGlyphLines(List<double> widths, double maxWidth) {
  var lines = _packGreedy(widths, maxWidth);
  if (lines.length > 1) {
    final total = widths.fold<double>(0, (sum, w) => sum + w);
    for (var target = total / lines.length; target < maxWidth; target += 2) {
      final balanced = _packGreedy(widths, target);
      if (balanced.length == lines.length) {
        lines = balanced;
        break;
      }
    }
  }
  if (lines.length > 1 && lines.last.length == 1 && lines[lines.length - 2].length > 1) {
    lines.last.insert(0, lines[lines.length - 2].removeLast());
  }
  return lines;
}

List<List<int>> _packGreedy(List<double> widths, double maxWidth) {
  final lines = <List<int>>[];
  var current = <int>[];
  var used = 0.0;
  for (var i = 0; i < widths.length; i++) {
    if (current.isNotEmpty && used + widths[i] > maxWidth) {
      lines.add(current);
      current = <int>[];
      used = 0;
    }
    current.add(i);
    used += widths[i];
  }
  if (current.isNotEmpty) lines.add(current);
  return lines;
}

/// Same glyph line metrics as the Mushaf ([_QpcV2GlyphLine]: height 1.55).
const _kGlyphHeightFactor = 1.55;
const _kMaxFontSize = 30.0;
const _kMinFontSize = 15.0;

/// Renders one ayah with the Mushaf's QPC V2 page fonts into a PNG for the
/// home widget. The ink is an opaque mask on a transparent background; the
/// widget tints it with the theme ink, so light/dark needs no re-render.
class WidgetAyahRenderer {
  WidgetAyahRenderer({QpcV2Repository? repository})
      : _repository = repository ?? QpcV2MushafLayout.sharedRepository();

  final QpcV2Repository _repository;

  /// Bumped when the drawing changes so cached PNGs are rebuilt.
  static const renderVersion = 2;

  /// Returns the PNG path, reusing the cached file when nothing changed.
  /// Null when the glyph data is missing or the ayah cannot fit the bucket.
  Future<String?> renderCached({
    required int surah,
    required int ayah,
    required int page,
    required WidgetAyahBucket bucket,
    required double devicePixelRatio,
  }) async {
    final signature =
        'v$renderVersion|$surah:$ayah|${bucket.logicalWidth}x${bucket.logicalHeight}|'
        '${devicePixelRatio.toStringAsFixed(2)}';
    final cachedSig = await HomeWidget.getWidgetData<String>(bucket.signatureKey);
    final cachedPath = await HomeWidget.getWidgetData<String>(bucket.key);
    if (cachedSig == signature &&
        cachedPath != null &&
        await File(cachedPath).exists()) {
      return cachedPath;
    }

    final stopwatch = Stopwatch()..start();
    final words = await _ayahWords(surah, ayah, page);
    if (words.isEmpty) return null;
    final png = await renderPng(
      words: words,
      bucket: bucket,
      devicePixelRatio: devicePixelRatio,
    );
    if (png == null) return null;
    final path = await HomeWidget.saveFile(bucket.key, png, extension: 'png');
    await HomeWidget.saveWidgetData<String>(bucket.signatureKey, signature);
    stopwatch.stop();
    debugPrint(
      'WidgetAyahRenderer: $surah:$ayah ${bucket.name} '
      '${png.lengthInBytes} B in ${stopwatch.elapsedMilliseconds} ms',
    );
    return path;
  }

  /// Draws [words] at the largest size (≤ [_kMaxFontSize]) whose packed lines
  /// fit the bucket. Null when even [_kMinFontSize] needs too many lines.
  static Future<Uint8List?> renderPng({
    required List<WidgetGlyphWord> words,
    required WidgetAyahBucket bucket,
    required double devicePixelRatio,
  }) async {
    for (var size = _kMaxFontSize; size >= _kMinFontSize; size -= 1) {
      final widths = [for (final w in words) _measure([w], size).width];
      final lines = packGlyphLines(widths, bucket.logicalWidth);
      if (lines.length > bucket.maxLines) continue;

      final painters = [
        for (final line in lines) _measure([for (final i in line) words[i]], size),
      ];
      final height = painters.fold<double>(0, (sum, p) => sum + p.height);
      if (height > bucket.logicalHeight && size > _kMinFontSize) continue;

      final width = painters.fold<double>(0, (m, p) => math.max(m, p.width));
      return _paint(painters, width, height, devicePixelRatio);
    }
    return null;
  }

  static TextPainter _measure(List<WidgetGlyphWord> words, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          height: _kGlyphHeightFactor,
          letterSpacing: 0,
          wordSpacing: 0,
          color: const Color(0xFF000000),
        ),
        children: [
          for (final w in words)
            TextSpan(text: w.glyph, style: TextStyle(fontFamily: w.fontFamily)),
        ],
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      maxLines: 1,
    )..layout();
    return painter;
  }

  static Future<Uint8List?> _paint(
    List<TextPainter> painters,
    double width,
    double height,
    double dpr,
  ) async {
    final pixelWidth = (width * dpr).ceil();
    final pixelHeight = (height * dpr).ceil();
    if (pixelWidth <= 0 || pixelHeight <= 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    var y = 0.0;
    for (final painter in painters) {
      painter.paint(canvas, Offset((width - painter.width) / 2, y));
      y += painter.height;
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelWidth, pixelHeight);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  /// The ayah's glyph words from the 15-line layout, with each word's page
  /// font loaded. [page] comes from the verses table, whose numbering can be
  /// one off from the QPC V2 layout (94:5 is 596 there, 597 here), and an ayah
  /// can run onto the next page, so the neighbours are read too.
  Future<List<WidgetGlyphWord>> _ayahWords(int surah, int ayah, int page) async {
    final words = <WidgetGlyphWord>[];
    for (final p in [page - 1, page, page + 1, page + 2]) {
      if (p < 1 || p > 604) continue;
      final lines = await _repository.getPageLines(p);
      final onPage = [
        for (final line in lines)
          if (line.isAyah)
            for (final w in line.words)
              if (w.surah == surah && w.ayah == ayah) w,
      ];
      if (onPage.isEmpty) {
        if (words.isNotEmpty) break;
        continue;
      }
      final family = await QpcV2FontLoader.ensurePageFontLoaded(p);
      words.addAll([
        for (final w in onPage) WidgetGlyphWord(glyph: w.glyph, fontFamily: family),
      ]);
    }
    return words;
  }
}
