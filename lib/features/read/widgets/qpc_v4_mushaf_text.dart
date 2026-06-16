import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/mushaf/qpc_v4_models.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/utils/bismillah.dart';
import 'package:quran_offline/core/widgets/surah_name_glyph.dart';
import 'package:quran_offline/features/read/widgets/mushaf_tap_long_press_recognizer.dart';

const _surahNameOuterGap = 12.0;
const _surahNameAfterAyahTop = 24.0;

/// Renders one Mushaf page using QPC V4 Tajweed glyph fonts.
class QpcV4MushafText extends ConsumerStatefulWidget {
  const QpcV4MushafText({
    super.key,
    required this.content,
    required this.fontSize,
    required this.colorScheme,
    required this.ayahKeys,
    this.onAyahTap,
    this.onAyahLongPress,
    this.onBismillahTap,
    this.onBismillahLongPress,
    this.onAyahKeyCreated,
  });

  final QpcV4PageContent content;
  final double fontSize;
  final ColorScheme colorScheme;
  final Map<String, GlobalKey> ayahKeys;
  final void Function(int surahId, int ayahNo)? onAyahTap;
  final void Function(int surahId, int ayahNo)? onAyahLongPress;
  final void Function(int surahId)? onBismillahTap;
  final void Function(int surahId)? onBismillahLongPress;
  final VoidCallback? onAyahKeyCreated;

  @override
  ConsumerState<QpcV4MushafText> createState() => _QpcV4MushafTextState();
}

class _QpcV4MushafTextState extends ConsumerState<QpcV4MushafText> {
  final List<GestureRecognizer> _recognizers = [];

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
    final glyphSize = widget.fontSize * 1.08;
    _recognizers.clear();

    final children = <Widget>[];
    var previousLineWasAyah = false;

    for (final line in widget.content.lines) {
      if (line.isSurahName && line.surahId != null) {
        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: previousLineWasAyah
                  ? _surahNameAfterAyahTop
                  : _surahNameOuterGap,
              bottom: _surahNameOuterGap,
            ),
            child: SurahNameMushafGlyph(
              surahId: line.surahId!,
              mushafFontSize: widget.fontSize,
            ),
          ),
        );
        previousLineWasAyah = false;
        continue;
      }

      if (line.isBasmallah && line.surahId != null) {
        final surahId = line.surahId!;
        final isRecitingBismillah = audio.isPlayingBismillah &&
            audio.surahId == surahId;

        final recognizer = MushafTapLongPressRecognizer(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onBismillahTap?.call(surahId);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            widget.onBismillahLongPress?.call(surahId);
          },
        );
        _recognizers.add(recognizer);

        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text.rich(
                TextSpan(
                  text: '\uFDFD',
                  recognizer: recognizer,
                  style: TextStyle(
                    fontFamily: widget.content.fontFamily,
                    fontSize: glyphSize - 2,
                    height: 1.55,
                    color: widget.colorScheme.onSurface,
                    backgroundColor: isRecitingBismillah
                        ? widget.colorScheme.primary.withValues(alpha: 0.14)
                        : null,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
        previousLineWasAyah = false;
        continue;
      }

      if (!line.isAyah || line.words.isEmpty) continue;

      previousLineWasAyah = true;
      final spans = <InlineSpan>[];
      int? lastAyahKeySurah;
      int? lastAyahKeyAyah;

      for (final word in line.words) {
        final recitingAyahNo = audio.isPlayingBismillah
            ? Bismillah.audioAyahNo
            : audio.ayahNo;
        final isReciting = audio.surahId == word.surah &&
            recitingAyahNo != null &&
            word.ayah == recitingAyahNo;

        final keyName = '${word.surah}_${word.ayah}';
        widget.ayahKeys.putIfAbsent(keyName, GlobalKey.new);
        final ayahKey = widget.ayahKeys[keyName]!;

        if (lastAyahKeySurah != word.surah || lastAyahKeyAyah != word.ayah) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: KeyedSubtree(
                key: ayahKey,
                child: const SizedBox(width: 0, height: 0),
              ),
            ),
          );
          lastAyahKeySurah = word.surah;
          lastAyahKeyAyah = word.ayah;
        }

        final recognizer = MushafTapLongPressRecognizer(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onAyahTap?.call(word.surah, word.ayah);
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            widget.onAyahLongPress?.call(word.surah, word.ayah);
          },
        );
        _recognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: word.glyph,
            style: TextStyle(
              fontFamily: widget.content.fontFamily,
              fontSize: glyphSize,
              height: 1.5,
              color: widget.colorScheme.onSurface,
              backgroundColor: isReciting
                  ? widget.colorScheme.primary.withValues(alpha: 0.14)
                  : null,
            ),
            recognizer: recognizer,
          ),
        );
      }

      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(children: spans),
              textAlign: line.isCentered ? TextAlign.center : TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAyahKeyCreated?.call();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
