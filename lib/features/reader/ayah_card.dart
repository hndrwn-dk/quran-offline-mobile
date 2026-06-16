import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/audio/playback_actions.dart';
import 'package:quran_offline/core/providers/audio_player_provider.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';
import 'package:quran_offline/core/utils/transliteration_formatter.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';
import 'package:quran_offline/core/share/verse_share.dart';
import 'package:quran_offline/core/tajweed/tajweed_report.dart';
import 'package:quran_offline/features/reader/widgets/ayah_tafsir_panel.dart';
import 'package:quran_offline/features/reader/widgets/highlight_color_picker.dart';
import 'package:quran_offline/features/reader/widgets/note_editor_dialog.dart';

class AyahCard extends ConsumerStatefulWidget {
  final Verse verse;

  const AyahCard({
    super.key,
    required this.verse,
  });

  @override
  ConsumerState<AyahCard> createState() => _AyahCardState();
}

class _AyahCardState extends ConsumerState<AyahCard> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final bookmarked = await isBookmarked(ref, widget.verse.surahId, widget.verse.ayahNo);
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
      });
    }
  }

  void _togglePlay(AudioPlayerState audio) {
    final notifier = ref.read(audioPlayerProvider.notifier);
    final isCurrentAyah = audio.surahId == widget.verse.surahId &&
        audio.ayahNo == widget.verse.ayahNo;
    if (isCurrentAyah) {
      notifier.toggle();
      return;
    }
    final surahs = ref.read(surahNamesProvider).valueOrNull;
    final surahName = surahs
        ?.firstWhere(
          (s) => s.id == widget.verse.surahId,
          orElse: () => surahs.first,
        )
        .englishName;
    PlaybackActions.playAyah(
      context,
      ref,
      widget.verse.surahId,
      widget.verse.ayahNo,
      surahName: surahName,
    );
  }

  String? _getTranslation(String lang) {
    final rawTranslation = switch (lang) {
      'en' => widget.verse.trEn,
      'id' => widget.verse.trId,
      'zh' => widget.verse.trZh,
      'ja' => widget.verse.trJa,
      _ => widget.verse.trId,
    };
    return rawTranslation != null ? TranslationCleaner.clean(rawTranslation) : null;
  }

  String _getDisplayTransliteration(AppSettings settings) {
    if (settings.useTajweedTransliteration) {
      final tj = widget.verse.translitTj;
      if (tj != null && tj.trim().isNotEmpty) return tj.trim();
      final tl = widget.verse.translit;
      if (tl != null && tl.trim().isNotEmpty) return tl.trim();
      return '';
    }
    return TransliterationFormatter.displayTransliteration(
      tlRaw: widget.verse.translit,
      style: settings.transliterationStyle,
      tajweedHtml: widget.verse.tajweed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final translation = _getTranslation(settings.language);
    final colorScheme = Theme.of(context).colorScheme;
    
    // Watch for notes and highlights
    ref.watch(noteRefreshProvider);
    ref.watch(highlightRefreshProvider);
    final noteAsync = ref.watch(noteProvider((surahId: widget.verse.surahId, ayahNo: widget.verse.ayahNo)));
    final highlightAsync = ref.watch(highlightProvider((surahId: widget.verse.surahId, ayahNo: widget.verse.ayahNo)));
    
    final hasNote = noteAsync.valueOrNull != null;
    final highlightColor = highlightAsync.valueOrNull?.color;
    final displayHighlight = highlightColor != null
        ? highlightDisplayColor(highlightColor)
        : null;

    final audio = ref.watch(audioPlayerProvider);
    final isCurrentAyah = audio.surahId == widget.verse.surahId &&
        audio.ayahNo == widget.verse.ayahNo;
    final isPlayingThis = isCurrentAyah && audio.isPlaying;

    final BoxDecoration? decoration = isCurrentAyah
        ? BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.4),
              width: 1,
            ),
          )
        : displayHighlight != null
            ? BoxDecoration(
                color: displayHighlight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: displayHighlight.withValues(alpha: 0.3),
                  width: 1,
                ),
              )
            : null;

    return GestureDetector(
      onLongPress: () => _showAyahActions(context, settings, hasNote, highlightColor),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.verse.surahId}:${widget.verse.ayahNo}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isCurrentAyah
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: isCurrentAyah ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (isCurrentAyah) ...[
                      const SizedBox(width: 8),
                      Icon(
                        isPlayingThis ? Icons.graphic_eq : Icons.volume_up_outlined,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isPlayingThis ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                        size: 20,
                      ),
                      color: isCurrentAyah
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _togglePlay(audio),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        highlightColor != null ? Icons.format_color_fill : Icons.format_color_fill_outlined,
                        size: 20,
                      ),
                      color: displayHighlight != null
                          ? displayHighlight
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showHighlightPicker(context),
                    ),
                    IconButton(
                      icon: Icon(
                        hasNote ? Icons.note : Icons.note_outlined,
                        size: 20,
                      ),
                      color: hasNote
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showNoteEditor(context, noteAsync.valueOrNull?.note),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20),
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _shareAyah(context, settings),
                    ),
                    IconButton(
                      icon: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        size: 20,
                      ),
                      color: _isBookmarked
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await toggleBookmark(
                          ref,
                          widget.verse.surahId,
                          widget.verse.ayahNo,
                        );
                        await _checkBookmark();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              label: 'Arabic text',
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: settings.showTajweed
                      ? _buildTajweedText(settings, colorScheme)
                      : _buildPlainArabicText(settings, colorScheme),
                ),
              ),
            ),
            if (settings.showTransliteration) ...[
              if (_getDisplayTransliteration(settings).isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  _getDisplayTransliteration(settings),
                  style: TextStyle(
                  fontSize: settings.translationFontSize * 0.85,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            ],
            if (settings.showTranslation && translation != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                translation,
                style: TextStyle(
                  fontSize: settings.translationFontSize,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            AyahTafsirPanel(
              surahId: widget.verse.surahId,
              ayahNo: widget.verse.ayahNo,
            ),
          ],
        ),
      ),
    );
  }

  void _showAyahActions(BuildContext context, AppSettings settings, bool hasNote, int? highlightColor) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(highlightColor != null ? Icons.format_color_fill : Icons.format_color_fill_outlined),
              title: Text(highlightColor != null ? 'Change highlight' : 'Highlight'),
              onTap: () {
                Navigator.pop(context);
                _showHighlightPicker(context);
              },
            ),
            ListTile(
              leading: Icon(hasNote ? Icons.note : Icons.note_outlined),
              title: Text(hasNote ? 'Edit note' : 'Add note'),
              onTap: () {
                Navigator.pop(context);
                final noteAsync = ref.read(noteProvider((surahId: widget.verse.surahId, ayahNo: widget.verse.ayahNo)));
                _showNoteEditor(context, noteAsync.valueOrNull?.note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(AppLocalizations.getShareAction(settings.appLanguage)),
              onTap: () {
                Navigator.pop(context);
                _shareAyah(context, settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(
                AppLocalizations.getSettingsText(
                  'report_tajweed_action',
                  settings.appLanguage,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                TajweedReport.launch(
                  context: context,
                  language: settings.appLanguage,
                  surahId: widget.verse.surahId,
                  ayahNo: widget.verse.ayahNo,
                  arabicSnippet: widget.verse.arabic,
                );
              },
            ),
            ListTile(
              leading: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
              title: Text(_isBookmarked ? 'Remove bookmark' : 'Bookmark'),
              onTap: () async {
                Navigator.pop(context);
                await toggleBookmark(
                  ref,
                  widget.verse.surahId,
                  widget.verse.ayahNo,
                );
                await _checkBookmark();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteEditor(BuildContext context, String? existingNote) {
    showDialog(
      context: context,
      builder: (context) => NoteEditorDialog(
        surahId: widget.verse.surahId,
        ayahNo: widget.verse.ayahNo,
        existingNote: existingNote,
      ),
    );
  }

  void _showHighlightPicker(BuildContext context) {
    final highlightAsync = ref.read(highlightProvider((surahId: widget.verse.surahId, ayahNo: widget.verse.ayahNo)));
    showDialog(
      context: context,
      builder: (context) => HighlightColorPicker(
        surahId: widget.verse.surahId,
        ayahNo: widget.verse.ayahNo,
        currentColor: highlightAsync.valueOrNull?.color,
      ),
    );
  }

  /// Renders plain Arabic (tajweed off). Uses the same source as tajweed ON when
  /// available: strip tags from verse.tajweed and normalize, so ٱ/ٲ never become circles.
  Widget _buildPlainArabicText(AppSettings settings, ColorScheme colorScheme) {
    final String textToShow;
    if (widget.verse.tajweed != null && widget.verse.tajweed!.isNotEmpty) {
      textToShow = TajweedText.plainArabicFromTajweedHtml(widget.verse.tajweed!);
    } else {
      textToShow = TajweedText.normalizeArabicForDisplay(widget.verse.arabic);
    }
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return Localizations.override(
      context: context,
      locale: const Locale('ar'),
      child: SelectableText(
        textToShow,
        style: TajweedText.arabicDisplayStyle(
          fontSize: settings.arabicFontSize * 1.15,
          color: colorScheme.onSurface,
          height: 1.7,
          isLightTheme: isLightTheme,
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildTajweedText(AppSettings settings, ColorScheme colorScheme) {
    final tajweedHtml = widget.verse.tajweed;
    
    if (tajweedHtml == null || tajweedHtml.isEmpty) {
      // Fallback to plain Arabic with same normalization when no tajweed data
      return _buildPlainArabicText(settings, colorScheme);
    }
    
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    return TajweedText(
      tajweedHtml: tajweedHtml,
      fontSize: settings.arabicFontSize * 1.15,
      defaultColor: colorScheme.onSurface,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      height: 1.7,
      replaceWaslaWithAlif: true,
      isLightTheme: isLightTheme,
    );
  }

  Future<void> _shareAyah(BuildContext context, AppSettings settings) async {
    final surahs = ref.read(surahNamesProvider).valueOrNull;
    final surahName = surahs != null
        ? surahs
            .firstWhere(
              (s) => s.id == widget.verse.surahId,
              orElse: () => surahs.first,
            )
            .englishName
        : 'Surah ${widget.verse.surahId}';

    await VerseShare.share(
      context: context,
      verse: widget.verse,
      surahName: surahName,
      settings: settings,
    );
  }
}

