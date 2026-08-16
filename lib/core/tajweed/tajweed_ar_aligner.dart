import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'tajweed_colors.dart';
import 'tajweed_html.dart';

class TajweedPaintRun {
  const TajweedPaintRun({required this.text, this.tajweedClass});

  final String text;
  final String? tajweedClass;
}

class TajweedArAlignResult {
  const TajweedArAlignResult._({
    required this.ok,
    required this.paintedText,
    required this.runs,
    this.failureReason,
  });

  factory TajweedArAlignResult.success({
    required String paintedText,
    required List<TajweedPaintRun> runs,
  }) =>
      TajweedArAlignResult._(
        ok: true,
        paintedText: paintedText,
        runs: runs,
      );

  factory TajweedArAlignResult.fail({
    required String arabic,
    required String reason,
  }) {
    debugPrint('TajweedArAligner fail: $reason');
    return TajweedArAlignResult._(
      ok: false,
      paintedText: arabic,
      runs: const [],
      failureReason: reason,
    );
  }

  final bool ok;
  final String paintedText;
  final List<TajweedPaintRun> runs;
  final String? failureReason;
}

class _TjTok {
  const _TjTok(this.rune, this.cls);
  final int rune;
  final String? cls;
}

/// Maps Foundation tajweed HTML onto JSON `ar` letters.
///
/// Failed alignment paints `ar` with no color. Never falls back to raw `tj`.
class TajweedArAligner {
  TajweedArAligner._();

  static final Map<String, TajweedArAlignResult> _cache = {};

  static const int _zwnj = 0x200C;
  static const int _tatweel = 0x0640;
  static const int _daggerAlif = 0x0670;
  static const int _wavyHamzaAlef = 0x0672;
  static const int _alef = 0x0627;
  static const int _alefHamzaAbove = 0x0623;
  static const int _hamzaAbove = 0x0654;

  static TajweedArAlignResult align({
    required String arabic,
    required String tajweedHtml,
    String? verseKey,
  }) {
    final key = verseKey ??
        '${arabic.length}:${tajweedHtml.length}:${arabic.hashCode}:${tajweedHtml.hashCode}';
    final cached = _cache[key];
    if (cached != null) return cached;
    final result = _alignUncached(arabic: arabic, tajweedHtml: tajweedHtml);
    _cache[key] = result;
    return result;
  }

  static TajweedArAlignResult _alignUncached({
    required String arabic,
    required String tajweedHtml,
  }) {
    final tjToks = _tokenize(tajweedHtml);
    final arRunes = arabic.runes.toList();
    final classes = List<String?>.filled(arRunes.length, null);

    var i = 0;
    var j = 0;
    String? lastClass;

    bool skipAr(int rune) =>
        rune == _zwnj || rune == 0x20 || rune == 0xA0 || rune == _tatweel;

    bool skipTj(int rune) =>
        rune == _zwnj || rune == 0x20 || rune == 0xA0 || rune == _tatweel;

    bool lettersMatch(int a, int t) {
      if (a == t) return true;
      if (a == _daggerAlif && t == _wavyHamzaAlef) return true;
      if (a == _wavyHamzaAlef && t == _daggerAlif) return true;
      // Color-position only. Painted letters still come from `ar` (U+06DF).
      // Do not alias U+06DF with U+06E0 (different waqf rules).
      if (a == 0x06DF && t == 0x0652) return true;
      if (a == 0x0652 && t == 0x06DF) return true;
      return false;
    }

    while (i < arRunes.length && j < tjToks.length) {
      final a = arRunes[i];
      final t = tjToks[j];

      if (a == _zwnj) {
        classes[i] = lastClass;
        i++;
        continue;
      }
      if (t.rune == _zwnj) {
        j++;
        continue;
      }

      if (lettersMatch(a, t.rune)) {
        classes[i] = t.cls;
        lastClass = t.cls ?? lastClass;
        i++;
        j++;
        continue;
      }

      if (a == _alefHamzaAbove &&
          t.rune == _alef &&
          j + 1 < tjToks.length &&
          tjToks[j + 1].rune == _hamzaAbove) {
        classes[i] = t.cls ?? tjToks[j + 1].cls;
        lastClass = classes[i] ?? lastClass;
        i++;
        j += 2;
        continue;
      }
      if (a == _alef &&
          i + 1 < arRunes.length &&
          arRunes[i + 1] == _hamzaAbove &&
          t.rune == _alefHamzaAbove) {
        classes[i] = t.cls;
        classes[i + 1] = t.cls;
        lastClass = t.cls ?? lastClass;
        i += 2;
        j++;
        continue;
      }

      if (skipAr(a) && !lettersMatch(a, t.rune)) {
        classes[i] = lastClass;
        i++;
        continue;
      }
      if (skipTj(t.rune)) {
        j++;
        continue;
      }

      return TajweedArAlignResult.fail(
        arabic: arabic,
        reason:
            'mismatch at ar[$i]=U+${a.toRadixString(16)} tj[$j]=U+${t.rune.toRadixString(16)}',
      );
    }

    while (i < arRunes.length) {
      if (!skipAr(arRunes[i]) && arRunes[i] != _zwnj) {
        return TajweedArAlignResult.fail(
          arabic: arabic,
          reason: 'leftover ar at $i',
        );
      }
      classes[i] = lastClass;
      i++;
    }
    while (j < tjToks.length) {
      if (!skipTj(tjToks[j].rune) && tjToks[j].rune != _zwnj) {
        return TajweedArAlignResult.fail(
          arabic: arabic,
          reason: 'leftover tj at $j',
        );
      }
      j++;
    }

    final runs = <TajweedPaintRun>[];
    final buf = StringBuffer();
    String? runClass;
    void flush() {
      if (buf.isEmpty) return;
      runs.add(TajweedPaintRun(text: buf.toString(), tajweedClass: runClass));
      buf.clear();
    }

    for (var k = 0; k < arRunes.length; k++) {
      final cls = classes[k];
      if (buf.isEmpty) {
        runClass = cls;
      } else if (cls != runClass) {
        flush();
        runClass = cls;
      }
      buf.writeCharCode(arRunes[k]);
    }
    flush();

    return TajweedArAlignResult.success(paintedText: arabic, runs: runs);
  }

  static List<TextSpan> spansFor({
    required BuildContext context,
    required String arabic,
    required String tajweedHtml,
    required TextStyle baseStyle,
    required Color defaultColor,
    String? verseKey,
    GestureRecognizer? recognizer,
    Color? backgroundColor,
  }) {
    final result = align(
      arabic: arabic,
      tajweedHtml: tajweedHtml,
      verseKey: verseKey,
    );
    if (!result.ok || result.runs.isEmpty) {
      return [
        TextSpan(
          text: arabic,
          style: baseStyle.copyWith(backgroundColor: backgroundColor),
          recognizer: recognizer,
        ),
      ];
    }
    return [
      for (final run in result.runs)
        TextSpan(
          text: run.text,
          style: baseStyle.copyWith(
            color: run.tajweedClass == null || run.tajweedClass!.isEmpty
                ? defaultColor
                : TajweedColors.colorForClass(
                    run.tajweedClass!,
                    context,
                    defaultColor: defaultColor,
                  ),
            backgroundColor: backgroundColor,
          ),
          recognizer: recognizer,
        ),
    ];
  }

  static List<_TjTok> _tokenize(String html) {
    final prepared = TajweedHtml.prepareForParsing(html);
    final toks = <_TjTok>[];
    final stack = <String?>[null];
    var skipEnd = 0;
    final parts = RegExp(r'<[^>]+>|[^<]+').allMatches(prepared);
    for (final m in parts) {
      final chunk = m.group(0)!;
      if (chunk.startsWith('<')) {
        final inner = chunk.substring(1, chunk.length - 1).trim();
        if (inner.isEmpty) continue;
        final isClose = inner.startsWith('/');
        final body = isClose ? inner.substring(1).trim() : inner;
        final name = body.split(RegExp(r'[\s/]')).first.toLowerCase();
        final cls = _classAttr(body);
        if (isClose) {
          if (name == 'span' && skipEnd > 0) {
            skipEnd--;
          } else if (stack.length > 1) {
            stack.removeLast();
          }
          continue;
        }
        final endSpan = name == 'span' &&
            (cls == 'end' || cls == '"end"' || cls == "'end'");
        if (endSpan) {
          skipEnd++;
          continue;
        }
        if (name == 'tajweed' || name == 'span' || name == 'class') {
          stack.add(cls ?? stack.last);
        }
        continue;
      }
      if (skipEnd > 0) continue;
      final current = stack.last;
      for (final rune in chunk.runes) {
        toks.add(_TjTok(rune, current));
      }
    }
    return toks;
  }

  static String? _classAttr(String tagBody) {
    final dq = RegExp(r'class\s*=\s*"([^"]+)"', caseSensitive: false)
        .firstMatch(tagBody);
    if (dq != null) return dq.group(1)!.trim();
    final sq = RegExp(r"class\s*=\s*'([^']+)'", caseSensitive: false)
        .firstMatch(tagBody);
    if (sq != null) return sq.group(1)!.trim();
    final bq = RegExp(r'class\s*=\s*([^\s>/]+)', caseSensitive: false)
        .firstMatch(tagBody);
    return bq?.group(1)?.trim();
  }
}
