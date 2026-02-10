import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/highlights_provider.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';
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

    return GestureDetector(
      onLongPress: () => _showAyahActions(context, settings, hasNote, highlightColor),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: highlightColor != null
            ? BoxDecoration(
                color: Color(highlightColor).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(highlightColor).withOpacity(0.3),
                  width: 1,
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.verse.surahId}:${widget.verse.ayahNo}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        highlightColor != null ? Icons.format_color_fill : Icons.format_color_fill_outlined,
                        size: 20,
                      ),
                      color: highlightColor != null
                          ? Color(highlightColor)
                          : colorScheme.onSurfaceVariant.withOpacity(0.6),
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
                          : colorScheme.onSurfaceVariant.withOpacity(0.6),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showNoteEditor(context, noteAsync.valueOrNull?.note),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 20),
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
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
                          : colorScheme.onSurfaceVariant.withOpacity(0.6),
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
                      : SelectableText(
                          widget.verse.arabic,
                          style: TextStyle(
                            fontSize: settings.arabicFontSize * 1.15,
                            fontFamily: 'UthmanicHafsV22',
                            fontFamilyFallback: const ['UthmanicHafs'],
                            height: 1.7,
                            color: colorScheme.onSurface,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                ),
              ),
            ),
            if (settings.showTransliteration && widget.verse.translit != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                widget.verse.translit!,
                style: TextStyle(
                  fontSize: settings.translationFontSize * 0.85,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
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
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareAyah(context, settings);
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

  Widget _buildTajweedText(AppSettings settings, ColorScheme colorScheme) {
    final tajweedHtml = widget.verse.tajweed;
    
    if (tajweedHtml == null || tajweedHtml.isEmpty) {
      // Fallback to regular text if tajweed not available
      return SelectableText(
        widget.verse.arabic,
        style: TextStyle(
          fontSize: settings.arabicFontSize * 1.15,
          fontFamily: 'UthmanicHafsV22',
          fontFamilyFallback: const ['UthmanicHafs'],
          height: 1.7,
          color: colorScheme.onSurface,
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      );
    }
    
    return TajweedText(
      tajweedHtml: tajweedHtml,
      fontSize: settings.arabicFontSize * 1.15,
      defaultColor: colorScheme.onSurface,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      height: 1.7,
    );
  }

  Future<void> _shareAyah(BuildContext context, AppSettings settings) async {
    try {
      final translation = _getTranslation(settings.language);
      
      // Get surah name
      final surahsAsync = ref.read(surahNamesProvider);
      final surahs = surahsAsync.valueOrNull;
      final surahName = surahs != null
          ? surahs.firstWhere(
              (s) => s.id == widget.verse.surahId,
              orElse: () => surahs.first,
            ).englishName
          : 'Surah ${widget.verse.surahId}';
      
      // Render Arabic text with UthmanicHafsV22 font as image
      final imageFile = await _renderArabicTextToImage(context, settings);
      
      // Prepare text content with refined format
      final buffer = StringBuffer();
      
      // Header: "Allah Subhanahu Wa Ta'ala berfirman:" - use app language for UI text
      buffer.writeln(AppLocalizations.getShareHeader(settings.appLanguage));
      buffer.writeln('');
      
      // Arabic text will be included as image
      // Transliteration (if available)
      if (widget.verse.translit != null && widget.verse.translit!.isNotEmpty) {
        buffer.writeln(widget.verse.translit);
        buffer.writeln('');
      }
      
      // Translation
      if (translation != null) {
        buffer.writeln('"$translation"');
        buffer.writeln('');
      }
      
      // Reference: (QS. Al-Baqarah 2: Ayat 186) - use app language for UI text
      final ayahLabel = AppLocalizations.getAyahLabel(settings.appLanguage);
      buffer.writeln('(QS. $surahName ${widget.verse.surahId}: $ayahLabel ${widget.verse.ayahNo})');
      buffer.writeln('');
      
      // Link
      buffer.writeln('https://www.tursinalabs.com/products/quranoffline');

      // Share image and text
      if (imageFile != null) {
        await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: buffer.toString(),
        );
        // Clean up temporary file after sharing
        try {
          await imageFile.delete();
        } catch (_) {
          // Ignore deletion errors
        }
      } else {
        // Fallback to text-only sharing if image rendering fails
        // Prepend Arabic text to the existing buffer (which already has header, transliteration, translation, reference, link)
        final fallbackBuffer = StringBuffer();
        fallbackBuffer.writeln(AppLocalizations.getShareHeader(settings.appLanguage));
        fallbackBuffer.writeln('');
        fallbackBuffer.writeln(widget.verse.arabic); // Add Arabic text
        fallbackBuffer.writeln('');
        // Append the rest from buffer (transliteration, translation, reference, link)
        // Skip the header line and empty line from buffer
        final bufferLines = buffer.toString().split('\n');
        // Start from index 2 to skip header and empty line
        for (int i = 2; i < bufferLines.length; i++) {
          fallbackBuffer.writeln(bufferLines[i]);
        }
        await Share.share(fallbackBuffer.toString());
      }
    } catch (e) {
      // Fallback to text-only sharing on error
      try {
        final translation = _getTranslation(settings.language);
        final surahsAsync = ref.read(surahNamesProvider);
        final surahs = surahsAsync.valueOrNull;
        final surahName = surahs != null
            ? surahs.firstWhere(
                (s) => s.id == widget.verse.surahId,
                orElse: () => surahs.first,
              ).englishName
            : 'Surah ${widget.verse.surahId}';
        
        final buffer = StringBuffer();
        buffer.writeln(AppLocalizations.getShareHeader(settings.appLanguage));
        buffer.writeln('');
        buffer.writeln(widget.verse.arabic);
        buffer.writeln('');
        if (widget.verse.translit != null && widget.verse.translit!.isNotEmpty) {
          buffer.writeln(widget.verse.translit);
          buffer.writeln('');
        }
        if (translation != null) {
          buffer.writeln('"$translation"');
          buffer.writeln('');
        }
        final ayahLabel = AppLocalizations.getAyahLabel(settings.appLanguage);
        buffer.writeln('(QS. $surahName ${widget.verse.surahId}: $ayahLabel ${widget.verse.ayahNo})');
        buffer.writeln('');
        buffer.writeln('https://www.tursinalabs.com/products/quranoffline');
        await Share.share(buffer.toString());
      } catch (_) {
        // Ultimate fallback
        final buffer = StringBuffer();
        buffer.writeln(widget.verse.arabic);
        buffer.writeln('');
        buffer.writeln('QS ${widget.verse.surahId}:${widget.verse.ayahNo}');
        buffer.writeln('');
        buffer.writeln('https://www.tursinalabs.com/products/quranoffline');
        await Share.share(buffer.toString());
      }
    }
  }

  Future<File?> _renderArabicTextToImage(BuildContext context, AppSettings settings) async {
    try {
      final colorScheme = Theme.of(context).colorScheme;
      final fontSize = settings.arabicFontSize * 1.5;
      final padding = 24.0;
      
      // Get the Arabic text (remove HTML tags if tajweed is enabled)
      String arabicText = widget.verse.arabic;
      if (settings.showTajweed && widget.verse.tajweed != null && widget.verse.tajweed!.isNotEmpty) {
        // For sharing, use plain text without tajweed HTML tags
        arabicText = widget.verse.tajweed!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .trim();
      }

      // Create a widget with Arabic text using UthmanicHafsV22 font
      // This ensures Flutter's font system properly loads the font
      final arabicWidget = Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.all(padding),
          color: colorScheme.surface,
          width: 600,
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(
            arabicText,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: 'UthmanicHafsV22',
              fontFamilyFallback: const ['UthmanicHafs'],
              height: 1.7,
              color: colorScheme.onSurface,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ),
      );

      // Use RenderRepaintBoundary to capture the widget as an image
      final repaintBoundary = RepaintBoundary(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Theme(
            data: Theme.of(context),
            child: arabicWidget,
          ),
        ),
      );

      // Build the widget tree
      final renderObject = repaintBoundary.createRenderObject(context);
      final pipelineOwner = PipelineOwner();
      final buildOwner = BuildOwner();
      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: renderObject,
        child: repaintBoundary,
      ).attachToRenderTree(buildOwner);

      // Wait for layout
      await Future.delayed(const Duration(milliseconds: 50));

      // Layout and paint
      pipelineOwner.rootNode = renderObject;
      renderObject.attach(pipelineOwner);
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      // Capture the image
      final image = await renderObject.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // Cleanup
      rootElement.unmount();
      renderObject.detach();
      image.dispose();

      if (byteData == null) return null;

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/ayah_${widget.verse.surahId}_${widget.verse.ayahNo}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return file;
    } catch (e) {
      // Return null on error, fallback to text-only sharing
      return null;
    }
  }
}

