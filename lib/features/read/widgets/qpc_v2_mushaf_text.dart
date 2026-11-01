import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
import 'package:quran_offline/core/mushaf/surah_name_ink_layout.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/utils/bismillah.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/features/read/widgets/mushaf_tap_long_press_recognizer.dart';

const _surahNameOuterGap = 16.0;
const _surahNameAfterAyahTop = 28.0;
const _surahNameBottomGap = 24.0;
const _gapBeforeAyahAfterSurahName = 18.0;
const _gapBeforeAyahAfterBasmallah = 12.0;
const _basmallahVerticalPad = 14.0;

enum _MushafLineKind { none, ayah, surahName, basmallah }

/// Renders one Mushaf page using QPC V2 glyph fonts.
///
/// Set [pageGrid] to render the page in the fixed 15-row reference box used by
/// [MushafPageFrame]: every page then shares one glyph size and one row grid, so
/// two pages of a spread can never drift in text size. The default (flowing)
/// mode keeps the legacy per-page width fitting.
class QpcV2MushafText extends StatelessWidget {
  const QpcV2MushafText({
    super.key,
    required this.content,
    required this.contentWidth,
    required this.fontSize,
    required this.colorScheme,
    required this.ayahKeys,
    this.pageGrid = false,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onBismillahTap,
    this.onBismillahLongPress,
    this.onAyahKeyCreated,
  });

  final QpcV2PageContent content;
  final double contentWidth;
  final double fontSize;
  final ColorScheme colorScheme;
  final Map<String, GlobalKey> ayahKeys;
  final bool pageGrid;
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;
  final VoidCallback? onAyahKeyCreated;

  @override
  Widget build(BuildContext context) {
    var effectiveSize = fontSize;
    if (!pageGrid) {
      final glyphLines = content.lines
          .where((line) => line.isAyah && line.glyphText.isNotEmpty)
          .map(
            (line) => (
              glyphText: line.glyphText,
              fontFamily: content.fontFamily,
              justify: false,
            ),
          );
      final cap = fontSize.clamp(
        kMushafGlyphMinFontSize,
        kMushafGlyphReferenceFontSize,
      );
      effectiveSize = computeQpcV2PageFontSize(
        lines: glyphLines,
        maxFontSize: cap,
        maxWidth: contentWidth,
      );
    }

    return SizedBox(
      width: contentWidth,
      child: _QpcV2MushafTextBody(
        content: content,
        fontSize: effectiveSize,
        lineMaxWidth: contentWidth,
        pageGrid: pageGrid,
        colorScheme: colorScheme,
        ayahKeys: ayahKeys,
        onAyahTap: onAyahTap,
        onAyahLongPress: onAyahLongPress,
        onBismillahTap: onBismillahTap,
        onBismillahLongPress: onBismillahLongPress,
        onAyahKeyCreated: onAyahKeyCreated,
      ),
    );
  }
}

class _QpcV2MushafTextBody extends StatelessWidget {
  const _QpcV2MushafTextBody({
    required this.content,
    required this.fontSize,
    required this.lineMaxWidth,
    required this.pageGrid,
    required this.colorScheme,
    required this.ayahKeys,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onBismillahTap,
    this.onBismillahLongPress,
    this.onAyahKeyCreated,
  });

  final QpcV2PageContent content;
  final double fontSize;
  final double lineMaxWidth;
  final bool pageGrid;
  final ColorScheme colorScheme;
  final Map<String, GlobalKey> ayahKeys;
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;
  final VoidCallback? onAyahKeyCreated;

  @override
  Widget build(BuildContext context) {
    if (pageGrid) {
      return _buildPageGrid();
    }

    final children = <Widget>[];
    final placedAyahAnchors = <String>{};
    var previousKind = _MushafLineKind.none;

    for (final line in content.lines) {
      if (line.isSurahName && line.surahId != null) {
        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: previousKind == _MushafLineKind.ayah
                  ? _surahNameAfterAyahTop
                  : _surahNameOuterGap,
              bottom: _surahNameBottomGap,
            ),
            child: SurahNameMushafGlyph(
              surahId: line.surahId!,
              mushafFontSize: fontSize,
            ),
          ),
        );
        previousKind = _MushafLineKind.surahName;
        continue;
      }

      if (line.isBasmallah) {
        final surahId = line.surahId;
        if (surahId == null || !Bismillah.shouldShowBismillah(surahId)) {
          previousKind = _MushafLineKind.none;
          continue;
        }
        children.add(
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: _basmallahVerticalPad),
            child: _QpcV2BasmallahRow(
              surahId: surahId,
              glyphText: content.bismillahGlyphText,
              fontFamily: content.basmallahFontFamily,
              fontSize: fontSize,
              lineMaxWidth: lineMaxWidth,
              colorScheme: colorScheme,
              onBismillahTap: onBismillahTap,
              onBismillahLongPress: onBismillahLongPress,
            ),
          ),
        );
        previousKind = _MushafLineKind.basmallah;
        continue;
      }

      if (!line.isAyah || line.words.isEmpty) continue;

      final topGap = switch (previousKind) {
        _MushafLineKind.surahName => _gapBeforeAyahAfterSurahName,
        _MushafLineKind.basmallah => _gapBeforeAyahAfterBasmallah,
        _ => 0.0,
      };
      if (topGap > 0) {
        children.add(SizedBox(height: topGap));
      }

      previousKind = _MushafLineKind.ayah;

      GlobalKey? lineAnchorKey;
      for (final word in line.words) {
        final keyName = '${word.surah}_${word.ayah}';
        if (placedAyahAnchors.contains(keyName)) continue;
        placedAyahAnchors.add(keyName);
        lineAnchorKey = ayahKeys.putIfAbsent(keyName, GlobalKey.new);
        break;
      }

      children.add(
        _QpcV2GlyphLineRow(
          line: line,
          fontFamily: content.fontFamily,
          fontSize: fontSize,
          lineMaxWidth: lineMaxWidth,
          colorScheme: colorScheme,
          ayahAnchorKey: lineAnchorKey,
          onAyahTap: onAyahTap,
          onAyahLongPress: onAyahLongPress,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onAyahKeyCreated?.call();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Fixed 15-row reference page: one row per QPC layout line, no gaps, so
  /// every page fills the same box and both pages of a spread keep an identical
  /// glyph size. Short pages (1–2) distribute their rows over the page instead
  /// of hugging the top.
  Widget _buildPageGrid() {
    const rowHeight = kMushafPageRowHeight;
    final lineHeightFactor = rowHeight / fontSize;
    final rows = <Widget>[];
    final placedAyahAnchors = <String>{};

    for (final line in content.lines) {
      if (line.isSurahName && line.surahId != null) {
        rows.add(
          SizedBox(
            height: rowHeight,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.22),
                  width: 0.8,
                ),
                color: colorScheme.primary.withValues(alpha: 0.035),
              ),
              child: SurahNameMushafInkGlyph(
                surahId: line.surahId!,
                color: colorScheme.primary,
                targetInkHeight: rowHeight * kSurahNameInkHeightFactor,
                maxInkWidth: lineMaxWidth * kSurahNameMaxInkWidthFactor,
              ),
            ),
          ),
        );
        continue;
      }

      if (line.isBasmallah) {
        final surahId = line.surahId;
        if (surahId == null || !Bismillah.shouldShowBismillah(surahId)) {
          continue;
        }
        rows.add(
          SizedBox(
            height: rowHeight,
            child: Center(
              child: _QpcV2BasmallahRow(
                surahId: surahId,
                glyphText: content.bismillahGlyphText,
                fontFamily: content.basmallahFontFamily,
                fontSize: fontSize,
                lineMaxWidth: lineMaxWidth,
                colorScheme: colorScheme,
                heightFactor: lineHeightFactor,
                verticalPadding: 0,
                onBismillahTap: onBismillahTap,
                onBismillahLongPress: onBismillahLongPress,
              ),
            ),
          ),
        );
        continue;
      }

      if (!line.isAyah || line.words.isEmpty) continue;

      GlobalKey? lineAnchorKey;
      for (final word in line.words) {
        final keyName = '${word.surah}_${word.ayah}';
        if (placedAyahAnchors.contains(keyName)) continue;
        placedAyahAnchors.add(keyName);
        lineAnchorKey = ayahKeys.putIfAbsent(keyName, GlobalKey.new);
        break;
      }

      rows.add(
        SizedBox(
          height: rowHeight,
          child: _QpcV2GlyphLineRow(
            line: line,
            fontFamily: content.fontFamily,
            fontSize: fontSize,
            lineMaxWidth: lineMaxWidth,
            colorScheme: colorScheme,
            heightFactor: lineHeightFactor,
            verticalPadding: 0,
            ayahAnchorKey: lineAnchorKey,
            onAyahTap: onAyahTap,
            onAyahLongPress: onAyahLongPress,
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onAyahKeyCreated?.call();
    });

    return SizedBox(
      height: kMushafPageLayoutHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}

class _AyahGlyphSegment {
  const _AyahGlyphSegment({
    required this.surah,
    required this.ayah,
    required this.glyphText,
  });

  final int surah;
  final int ayah;
  final String glyphText;
}

List<_AyahGlyphSegment> _groupLineWordsByAyah(List<QpcV2Word> words) {
  if (words.isEmpty) return const [];

  final segments = <_AyahGlyphSegment>[];
  var start = 0;
  for (var i = 1; i <= words.length; i++) {
    if (i == words.length ||
        words[i].surah != words[start].surah ||
        words[i].ayah != words[start].ayah) {
      final slice = words.sublist(start, i);
      segments.add(
        _AyahGlyphSegment(
          surah: slice.first.surah,
          ayah: slice.first.ayah,
          glyphText: slice.map((w) => w.glyph).join(),
        ),
      );
      start = i;
    }
  }
  return segments;
}

class _QpcV2BasmallahRow extends ConsumerStatefulWidget {
  const _QpcV2BasmallahRow({
    required this.surahId,
    required this.glyphText,
    required this.fontFamily,
    required this.fontSize,
    required this.lineMaxWidth,
    required this.colorScheme,
    this.heightFactor = 1.55,
    this.verticalPadding = 4,
    this.onBismillahTap,
    this.onBismillahLongPress,
  });

  final int surahId;
  final String glyphText;
  final String fontFamily;
  final double fontSize;
  final double lineMaxWidth;
  final ColorScheme colorScheme;
  final double heightFactor;
  final double verticalPadding;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;

  @override
  ConsumerState<_QpcV2BasmallahRow> createState() => _QpcV2BasmallahRowState();
}

class _QpcV2BasmallahRowState extends ConsumerState<_QpcV2BasmallahRow> {
  MushafTapLongPressRecognizer? _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = MushafTapLongPressRecognizer(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onBismillahTap?.call(widget.surahId);
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onBismillahLongPress?.call(widget.surahId);
      },
    );
  }

  @override
  void dispose() {
    _recognizer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioPlayerProvider);
    final isReciting = audio.isActive &&
        audio.isPlayingBismillah &&
        audio.surahId == widget.surahId;

    return _QpcV2GlyphLine(
      spans: [
        TextSpan(
          text: widget.glyphText,
          recognizer: _recognizer,
          style: TextStyle(
            backgroundColor: isReciting
                ? widget.colorScheme.primary.withValues(alpha: 0.14)
                : null,
          ),
        ),
      ],
      fontFamily: widget.fontFamily,
      fontSize: widget.fontSize,
      lineMaxWidth: widget.lineMaxWidth,
      color: widget.colorScheme.onSurface,
      heightFactor: widget.heightFactor,
      verticalPadding: widget.verticalPadding,
    );
  }
}

class _QpcV2GlyphLineRow extends ConsumerStatefulWidget {
  const _QpcV2GlyphLineRow({
    required this.line,
    required this.fontFamily,
    required this.fontSize,
    required this.lineMaxWidth,
    required this.colorScheme,
    this.heightFactor = 1.55,
    this.verticalPadding = 4,
    this.ayahAnchorKey,
    this.onAyahTap,
    this.onAyahLongPress,
  });

  final QpcV2Line line;
  final String fontFamily;
  final double fontSize;
  final double lineMaxWidth;
  final ColorScheme colorScheme;
  final double heightFactor;
  final double verticalPadding;
  final GlobalKey? ayahAnchorKey;
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;

  @override
  ConsumerState<_QpcV2GlyphLineRow> createState() => _QpcV2GlyphLineRowState();
}

class _QpcV2GlyphLineRowState extends ConsumerState<_QpcV2GlyphLineRow> {
  final List<MushafTapLongPressRecognizer> _recognizers = [];
  List<_AyahGlyphSegment> _segments = const [];

  @override
  void initState() {
    super.initState();
    _syncRecognizers();
  }

  @override
  void didUpdateWidget(_QpcV2GlyphLineRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line != widget.line) {
      _syncRecognizers();
    }
  }

  void _syncRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    _segments = _groupLineWordsByAyah(widget.line.words);

    for (final segment in _segments) {
      final surah = segment.surah;
      final ayah = segment.ayah;
      _recognizers.add(
        MushafTapLongPressRecognizer(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onAyahTap?.call(surah, ayah);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            widget.onAyahLongPress?.call(surah, ayah);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioPlayerProvider);
    final recitingAyahNo =
        audio.isPlayingBismillah ? Bismillah.audioAyahNo : audio.ayahNo;

    final spans = <TextSpan>[];
    for (var i = 0; i < _segments.length; i++) {
      final segment = _segments[i];
      final isReciting = audio.isActive &&
          recitingAyahNo != null &&
          segment.surah == audio.surahId &&
          segment.ayah == recitingAyahNo;

      spans.add(
        TextSpan(
          text: segment.glyphText,
          recognizer: _recognizers[i],
          style: TextStyle(
            backgroundColor: isReciting
                ? widget.colorScheme.primary.withValues(alpha: 0.14)
                : null,
          ),
        ),
      );
    }

    final line = _QpcV2GlyphLine(
      spans: spans,
      fontFamily: widget.fontFamily,
      fontSize: widget.fontSize,
      lineMaxWidth: widget.lineMaxWidth,
      color: widget.colorScheme.onSurface,
      textAlign: qpcV2GlyphLineAlign(isCentered: widget.line.isCentered),
      heightFactor: widget.heightFactor,
      verticalPadding: widget.verticalPadding,
    );

    final anchorKey = widget.ayahAnchorKey;
    if (anchorKey != null) {
      return KeyedSubtree(key: anchorKey, child: line);
    }
    return line;
  }
}

/// One layout line = one joined glyph string (QUL / Madinah style).
class _QpcV2GlyphLine extends StatelessWidget {
  const _QpcV2GlyphLine({
    required this.spans,
    required this.fontFamily,
    required this.fontSize,
    required this.lineMaxWidth,
    required this.color,
    this.textAlign = TextAlign.center,
    this.heightFactor = 1.55,
    this.verticalPadding = 4,
  });

  final List<InlineSpan> spans;
  final String fontFamily;
  final double fontSize;
  final double lineMaxWidth;
  final Color color;
  final TextAlign textAlign;
  final double heightFactor;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: heightFactor,
      letterSpacing: 0,
      wordSpacing: 0,
      color: color,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: SizedBox(
        width: lineMaxWidth,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(style: baseStyle, children: spans),
            textAlign: textAlign,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}
