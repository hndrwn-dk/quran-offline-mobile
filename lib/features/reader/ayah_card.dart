import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/translation_cleaner.dart';

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

    return GestureDetector(
      onLongPress: () => _showAyahActions(context, settings),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  child: SelectableText(
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
            if (translation != null) ...[
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

  void _showAyahActions(BuildContext context, AppSettings settings) {
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

  Future<void> _shareAyah(BuildContext context, AppSettings settings) async {
    final translation = _getTranslation(settings.language);
    final buffer = StringBuffer();
    buffer.writeln(widget.verse.arabic);
    if (translation != null) {
      buffer.writeln(translation);
    }
    buffer.writeln('QS ${widget.verse.surahId}:${widget.verse.ayahNo}');
    buffer.writeln('');
    buffer.writeln('https://www.tursinalab.com/products/quranoffline');

    await Share.share(buffer.toString());
  }
}

