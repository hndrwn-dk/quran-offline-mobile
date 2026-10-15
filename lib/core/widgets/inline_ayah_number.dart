import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/constants/quran_fonts.dart';
import 'package:quran_offline/core/models/bookmark_open_context.dart';
import 'package:quran_offline/core/providers/bookmark_provider.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';

/// End-of-ayah marker used on the Mushaf page.
///
/// Pass [markerColor] for a static mark (no bookmark tap). Mushaf omits it and
/// keeps the bookmark ring.
class InlineAyahNumber extends ConsumerStatefulWidget {
  const InlineAyahNumber({
    super.key,
    required this.ayahNo,
    required this.fontSize,
    required this.colorScheme,
    this.surahId,
    this.isReciting = false,
    this.markerColor,
  });

  final int ayahNo;
  final double fontSize;
  final ColorScheme colorScheme;
  final int? surahId;
  final bool isReciting;
  final Color? markerColor;

  @override
  ConsumerState<InlineAyahNumber> createState() => _InlineAyahNumberState();
}

class _InlineAyahNumberState extends ConsumerState<InlineAyahNumber> {
  bool _isBookmarked = false;
  bool _isCheckingBookmark = true;

  bool get _decorative => widget.markerColor != null;

  @override
  void initState() {
    super.initState();
    if (_decorative || widget.surahId == null) {
      _isCheckingBookmark = false;
    } else {
      _checkBookmark();
    }
  }

  Future<void> _checkBookmark() async {
    if (widget.surahId == null) {
      setState(() {
        _isCheckingBookmark = false;
      });
      return;
    }

    final bookmarked = await isBookmarked(
      ref,
      widget.surahId!,
      widget.ayahNo,
    );

    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
        _isCheckingBookmark = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (widget.surahId == null) return;

    await toggleBookmark(
      ref,
      widget.surahId!,
      widget.ayahNo,
      openContext: BookmarkOpenContext.mushaf,
    );

    await _checkBookmark();
  }

  @override
  Widget build(BuildContext context) {
    final displayNumber = MushafLayout.toArabicIndicDigits(widget.ayahNo.toString());

    ref.listen(bookmarkRefreshProvider, (previous, next) {
      if (_decorative) return;
      if (previous != next && widget.surahId != null) {
        _checkBookmark();
      }
    });

    final marker = widget.markerColor;
    final reciting = widget.isReciting;
    final borderColor = marker ??
        (_isBookmarked
            ? widget.colorScheme.primary
            : widget.colorScheme.outline.withValues(alpha: 0.3));
    final numberColor = marker ??
        (reciting || _isBookmarked
            ? widget.colorScheme.primary
            : widget.colorScheme.onSurface);

    return GestureDetector(
      onTap: !_decorative && widget.surahId != null && !_isCheckingBookmark
          ? _toggleBookmark
          : null,
      child: Container(
        padding: EdgeInsets.all(widget.fontSize * 0.2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: marker != null ? 1.5 : (_isBookmarked ? 2.0 : 1.5),
          ),
          color: marker != null
              ? Colors.transparent
              : reciting
                  ? widget.colorScheme.primary.withValues(alpha: 0.12)
                  : _isBookmarked
                      ? widget.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
        ),
        child: Text(
          displayNumber,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontFamily: QuranFonts.uthmanicHafsV22,
            fontFamilyFallback: QuranFonts.uthmanicFallbacks,
            color: numberColor,
            height: 1.0,
            fontWeight: marker != null
                ? FontWeight.w600
                : reciting || _isBookmarked
                    ? FontWeight.w700
                    : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
