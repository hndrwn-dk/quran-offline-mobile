import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_glyph_fit.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_models.dart';
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
class QpcV2MushafText extends StatelessWidget {
  const QpcV2MushafText({
    super.key,
    required this.content,
    required this.contentWidth,
    required this.fontSize,
    required this.colorScheme,
    required this.ayahKeys,
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
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;
  final VoidCallback? onAyahKeyCreated;

  @override
  Widget build(BuildContext context) {
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
    final effectiveSize = computeQpcV2PageFontSize(
      lines: glyphLines,
      maxFontSize: cap,
      maxWidth: contentWidth,
    );

    return SizedBox(
      width: contentWidth,
      child: _QpcV2MushafTextBody(
        content: content,
        fontSize: effectiveSize,
        lineMaxWidth: contentWidth,
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
  final ColorScheme colorScheme;
  final Map<String, GlobalKey> ayahKeys;
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;
  final VoidCallback? onAyahKeyCreated;

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(vertical: _basmallahVerticalPad),
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
    this.onBismillahTap,
    this.onBismillahLongPress,
  });

  final int surahId;
  final String glyphText;
  final String fontFamily;
  final double fontSize;
  final double lineMaxWidth;
  final ColorScheme colorScheme;
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
    this.ayahAnchorKey,
    this.onAyahTap,
    this.onAyahLongPress,
  });

  final QpcV2Line line;
  final String fontFamily;
  final double fontSize;
  final double lineMaxWidth;
  final ColorScheme colorScheme;
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
    final recitingAyahNo = audio.isPlayingBismillah
        ? Bismillah.audioAyahNo
        : audio.ayahNo;

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
      textAlign: widget.line.isCentered ? TextAlign.center : TextAlign.justify,
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
  });

  final List<InlineSpan> spans;
  final String fontFamily;
  final double fontSize;
  final double lineMaxWidth;
  final Color color;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: 1.55,
      letterSpacing: 0,
      wordSpacing: 0,
      color: color,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: lineMaxWidth,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(style: baseStyle, children: spans),
            textAlign: textAlign,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
      ),
    );
  }
}
