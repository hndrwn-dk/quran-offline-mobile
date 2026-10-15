import 'package:quran_offline/core/utils/arabic_search_normalizer.dart';

enum LibrarySearchKind { bookmark, note, highlight }

class LibrarySearchItem {
  const LibrarySearchItem({
    required this.kind,
    required this.surahId,
    required this.ayahNo,
    required this.surahName,
    required this.arabic,
    required this.translation,
    required this.note,
  });

  final LibrarySearchKind kind;
  final int surahId;
  final int ayahNo;
  final String surahName;
  final String arabic;
  final String translation;
  final String note;
}

/// Lowercase form with the article "al-", spaces, and hyphens removed.
///
/// "Al-Ikhlas", "al ikhlas", and "alikhlas" all become "ikhlas".
/// "Ali 'Imran" stays "ali'imran" so the name Ali is not treated as the article.
String normalizeLibraryText(String input) {
  var s = input.toLowerCase();
  s = s.replaceAll(RegExp(r'\bal[\s\-]+'), '');
  s = s.replaceAll(RegExp(r'[\s\-]+'), '');
  if (s.startsWith('al') && s.length >= 5) {
    final rest = s.substring(2);
    if (!rest.startsWith("i'")) {
      s = rest;
    }
  }
  return s;
}

bool libraryTextContains(String haystack, String query) {
  final h = normalizeLibraryText(haystack);
  final q = normalizeLibraryText(query);
  if (q.isEmpty || h.isEmpty) return false;
  return h.contains(q);
}

/// True when [query] is "s:a" (optional QS prefix) or a surah number.
bool libraryReferenceMatches(String query, int surahId, int ayahNo) {
  final compact = query.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
  if (compact.isEmpty) return false;
  final withoutQs = compact.replaceFirst(RegExp(r'^qs'), '');
  final pair = RegExp(r'^(\d+):(\d+)$').firstMatch(withoutQs);
  if (pair != null) {
    return int.parse(pair.group(1)!) == surahId &&
        int.parse(pair.group(2)!) == ayahNo;
  }
  if (RegExp(r'^\d+$').hasMatch(withoutQs)) {
    return int.parse(withoutQs) == surahId;
  }
  return false;
}

bool libraryEntryMatches(LibrarySearchItem item, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return true;
  if (libraryReferenceMatches(trimmed, item.surahId, item.ayahNo)) return true;
  for (final token in trimmed.split(RegExp(r'\s+'))) {
    if (libraryReferenceMatches(token, item.surahId, item.ayahNo)) return true;
  }
  if (libraryTextContains(item.surahName, trimmed)) return true;
  if (item.translation.isNotEmpty &&
      libraryTextContains(item.translation, trimmed)) {
    return true;
  }
  if (item.note.isNotEmpty && libraryTextContains(item.note, trimmed)) {
    return true;
  }
  return _arabicContains(item.arabic, trimmed);
}

bool _arabicContains(String arabic, String query) {
  if (arabic.isEmpty || !ArabicSearchNormalizer.containsArabic(query)) {
    return false;
  }
  final needle = ArabicSearchNormalizer.normalizeForSearch(query);
  if (needle.isEmpty) return false;
  final haystack = ArabicSearchNormalizer.normalizeForSearch(arabic);
  return haystack.contains(needle);
}

typedef LibraryMatchRange = ({int start, int end});

/// Ranges in [text] that should be marked for [query].
List<LibraryMatchRange> librarySnippetRanges(String text, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty || text.isEmpty) return const [];
  final ranges = <LibraryMatchRange>[];
  for (final token in trimmed.split(RegExp(r'\s+'))) {
    if (token.length < 2) continue;
    if (ArabicSearchNormalizer.containsArabic(token)) {
      ranges.addAll(_arabicRanges(text, token));
    } else {
      ranges.addAll(_latinRanges(text, token));
    }
  }
  return _mergeRanges(ranges);
}

List<LibraryMatchRange> _latinRanges(String text, String token) {
  final haystack = text.toLowerCase();
  final needle = token.toLowerCase();
  final ranges = <LibraryMatchRange>[];
  var from = 0;
  while (from < haystack.length) {
    final index = haystack.indexOf(needle, from);
    if (index < 0) break;
    ranges.add((start: index, end: index + needle.length));
    from = index + needle.length;
  }
  return ranges;
}

List<LibraryMatchRange> _arabicRanges(String text, String token) {
  final needle = ArabicSearchNormalizer.normalizeForSearch(token);
  if (needle.isEmpty) return const [];
  final mapped = _indexArabic(text);
  final ranges = <LibraryMatchRange>[];
  var from = 0;
  while (from < mapped.text.length) {
    final index = mapped.text.indexOf(needle, from);
    if (index < 0) break;
    final last = index + needle.length - 1;
    if (last >= mapped.origin.length) break;
    ranges.add((
      start: mapped.origin[index],
      end: mapped.origin[last] + 1,
    ));
    from = index + needle.length;
  }
  return ranges;
}

class _IndexedArabic {
  const _IndexedArabic(this.text, this.origin);
  final String text;
  final List<int> origin;
}

_IndexedArabic _indexArabic(String input) {
  final buffer = StringBuffer();
  final origin = <int>[];
  final tashkeel = RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]');
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    if (ch == '<') {
      final close = input.indexOf('>', i);
      if (close != -1) {
        i = close;
        continue;
      }
    }
    if (tashkeel.hasMatch(ch) ||
        ch == '\u0640' ||
        ch == '\u06DF' ||
        ch == '\u06DD') {
      continue;
    }
    var mapped = ch;
    if (ch == '\u0622' || ch == '\u0623' || ch == '\u0625' || ch == '\u0671') {
      mapped = '\u0627';
    } else if (ch == '\u0649') {
      mapped = '\u064A';
    }
    buffer.write(mapped);
    origin.add(i);
  }
  return _IndexedArabic(buffer.toString(), origin);
}

List<LibraryMatchRange> _mergeRanges(List<LibraryMatchRange> ranges) {
  if (ranges.length < 2) return ranges;
  final sorted = [...ranges]..sort((a, b) => a.start.compareTo(b.start));
  final merged = <LibraryMatchRange>[sorted.first];
  for (final range in sorted.skip(1)) {
    final last = merged.last;
    if (range.start <= last.end) {
      final end = range.end > last.end ? range.end : last.end;
      merged[merged.length - 1] = (start: last.start, end: end);
    } else {
      merged.add(range);
    }
  }
  return merged;
}
