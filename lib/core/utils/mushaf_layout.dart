import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageRange {
  final int surahId;
  final int startAyah;
  final int endAyah;

  PageRange({required this.surahId, required this.startAyah, required this.endAyah});

  factory PageRange.fromJson(Map<String, dynamic> json) => PageRange(
        surahId: json['s'] as int,
        startAyah: json['a1'] as int,
        endAyah: json['a2'] as int,
      );
}

class MushafToken {
  final String text;
  final bool isMarker;
  final int? surahId; // For markers: actual surah number
  final int? ayahNo;  // For markers: actual ayah number

  MushafToken({
    required this.text,
    this.isMarker = false,
    this.surahId,
    this.ayahNo,
  });

  Map<String, dynamic> toJson() => {
    't': text,
    'm': isMarker,
    if (surahId != null) 's': surahId,
    if (ayahNo != null) 'a': ayahNo,
  };

  factory MushafToken.fromJson(Map<String, dynamic> json) =>
      MushafToken(
        text: json['t'] as String,
        isMarker: json['m'] as bool? ?? false,
        surahId: json['s'] as int?,
        ayahNo: json['a'] as int?,
      );
}

class MushafLine {
  final List<MushafToken> tokens;
  final bool center;

  MushafLine(this.tokens, {this.center = false});

  Map<String, dynamic> toJson() => {
        'tokens': tokens.map((t) => t.toJson()).toList(),
        'c': center,
      };

  factory MushafLine.fromJson(Map<String, dynamic> json) => MushafLine(
        (json['tokens'] as List<dynamic>).map((e) => MushafToken.fromJson(e as Map<String, dynamic>)).toList(),
        center: json['c'] as bool? ?? false,
      );

  List<InlineSpan> toSpans(BuildContext context, double fontSize) {
    final style = DefaultTextStyle.of(context).style.copyWith(
          fontSize: fontSize,
          fontFamily: 'UthmanicHafsV22',
          fontFamilyFallback: const ['UthmanicHafs'],
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface,
        );
    return tokens.map((t) {
      if (t.isMarker) {
        // Use TextSpan with ornament glyph instead of WidgetSpan
        final ayahNo = t.ayahNo ?? int.tryParse(t.text) ?? 0;
        
        // Ensure ayahNo is valid (should never be 0 for real verses)
        if (ayahNo <= 0) {
          debugPrint('WARNING: Invalid ayahNo in marker token: ${t.text}, surahId: ${t.surahId}, ayahNo: ${t.ayahNo}');
          // Return empty span if invalid
          return const TextSpan(text: '');
        }
        
        final badgeFontSize = fontSize * 0.65;
        final arabicIndicNumber = _toArabicIndicDigits(ayahNo.toString());
        
        // Format: space + ornament glyph + number + space
        // Ensure number is not empty
        if (arabicIndicNumber.isEmpty) {
          debugPrint('WARNING: Empty arabicIndicNumber for ayahNo: $ayahNo');
          return const TextSpan(text: '');
        }
        
        return TextSpan(
          text: ' \u06DD$arabicIndicNumber ', // \u06DD = ayah ornament glyph
          style: style.copyWith(
            fontSize: badgeFontSize,
            height: 1.0,
          ),
        );
      }
      return TextSpan(text: t.text, style: style);
    }).toList();
  }

  /// Convert Western digits to Arabic-Indic digits
  static String _toArabicIndicDigits(String text) {
    const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return text.split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? arabicIndic[digit] : char;
    }).join();
  }
}

class MushafLayoutCache {
  static const _bucketSize = 8.0;

  static Future<String> _cachePath(double width, double fontSize) async {
    final dir = await getApplicationDocumentsDirectory();
    final bucket = (width / _bucketSize).floor() * _bucketSize;
    final fileName = 'mushaf_w${bucket.toInt()}_fs${fontSize.toInt()}_ff_uhafs.json';
    return '${dir.path}/$fileName';
  }

  static double _bucketWidth(double width) => (width / _bucketSize).floor() * _bucketSize;

  static Future<Map<String, dynamic>> _loadCache(String path) async {
    final file = File(path);
    if (!await file.exists()) return {};
    final txt = await file.readAsString();
    return jsonDecode(txt) as Map<String, dynamic>;
  }

  static Future<void> _saveCache(String path, Map<String, dynamic> data) async {
    final file = File(path);
    await file.writeAsString(jsonEncode(data));
  }

  static Future<List<MushafLine>> getPageLines(BuildContext context, int pageNo) async {
    final width = MediaQuery.of(context).size.width - 32; // padding margin
    final bucketWidth = _bucketWidth(width);
    final settings = ProviderScope.containerOf(context, listen: false).read(settingsProvider);
    final fontSize = settings.mushafFontSize;
    final path = await _cachePath(bucketWidth, fontSize);
    final cache = await _loadCache(path);
    final key = pageNo.toString();
    
    // Check cache but verify badge format is correct (cache version 2 = TextSpan with ornament)
    // For now, always recompute to ensure correct badge format
    // TODO: Add cache version field in future
    final lines = await _computeLines(context, pageNo, bucketWidth, fontSize);
    cache[key] = lines.map((l) => l.toJson()).toList();
    await _saveCache(path, cache);
    return lines;
  }

  static Future<void> prewarm(BuildContext context, int pageNo) async {
    if (pageNo > 604) return;
    final width = MediaQuery.of(context).size.width - 32;
    final bucketWidth = _bucketWidth(width);
    final settings = ProviderScope.containerOf(context, listen: false).read(settingsProvider);
    final fontSize = settings.mushafFontSize;
    final path = await _cachePath(bucketWidth, fontSize);
    final cache = await _loadCache(path);
    final key = pageNo.toString();
    if (cache.containsKey(key)) return;
    final lines = await _computeLines(context, pageNo, bucketWidth, fontSize);
    cache[key] = lines.map((l) => l.toJson()).toList();
    await _saveCache(path, cache);
  }

  static Future<void> invalidateCacheForFontSize(double fontSize) async {
    final dir = await getApplicationDocumentsDirectory();
    final pattern = RegExp(r'mushaf_w\d+_fs\d+_ff_uhafs\.json');
    final files = dir.listSync();
    for (final file in files) {
      if (file is File && pattern.hasMatch(file.path)) {
        // Extract filename from path (works on both Windows and Unix)
        final pathParts = file.path.split(RegExp(r'[/\\]'));
        final fileName = pathParts.isNotEmpty ? pathParts.last : file.path;
        final match = RegExp(r'fs(\d+)').firstMatch(fileName);
        if (match != null) {
          final cachedFontSize = double.parse(match.group(1)!);
          if (cachedFontSize == fontSize) {
            await file.delete();
          }
        }
      }
    }
  }

  static Future<void> invalidateAllCache() async {
    final dir = await getApplicationDocumentsDirectory();
    final pattern = RegExp(r'mushaf_w\d+_fs\d+_ff_uhafs\.json');
    final files = dir.listSync();
    for (final file in files) {
      if (file is File && pattern.hasMatch(file.path)) {
        await file.delete();
      }
    }
    debugPrint('All Mushaf cache invalidated');
  }

  static Future<Map<int, String>> _loadSurahNames() async {
    final data = await rootBundle.loadString('assets/quran/surah_names/manifest.json');
    final map = jsonDecode(data) as Map<String, dynamic>;
    final items = map['items'] as List<dynamic>;
    return {
      for (final item in items) item['id'] as int: item['display'] as String,
    };
  }

  // Sticky tokens: Arabic function words that should not appear at line edge
  static const Set<String> _stickyTokens = {
    'و', 'ف', 'ثم', 'على', 'من', 'في', 'ما', 'لا', 'أن', 'إن', 'إلا', 'حتى', 'لم', 'لن',
    'هم', 'رزقهم', 'بهم', 'لهم', 'عليهم', 'منهم', 'فيما', 'لما', 'فما', 'وما',
  };

  static bool _isStickyToken(String text) {
    final trimmed = text.trim();
    return _stickyTokens.contains(trimmed) || 
           _stickyTokens.any((sticky) => trimmed.startsWith(sticky));
  }

  /// Check if Arabic word is short (2 characters or less)
  static bool _isShortArabicWord(String text) {
    final stripped = text.replaceAll(RegExp(r'[^\u0600-\u06FF]'), '');
    return stripped.runes.length <= 2; // هم، من، في
  }

  static Future<List<MushafLine>> _computeLines(
      BuildContext context, int pageNo, double maxWidth, double fontSize) async {
    final ranges = await _pageRanges(pageNo);
    final surahNames = await _loadSurahNames();
    final db = ProviderScope.containerOf(context, listen: false).read(databaseProvider);
    final verses = <Verse>[];
    for (final r in ranges) {
      final part = await db.getVersesByRange(r.surahId, r.startAyah, r.endAyah);
      verses.addAll(part);
    }

    final tokens = <MushafToken>[];
    final lines = <MushafLine>[];
    void flushLine() {
      if (tokens.isNotEmpty) {
        lines.add(MushafLine(List.from(tokens)));
        tokens.clear();
      }
    }

    void insertSurahHeader(int surahId) {
      final name = surahNames[surahId] ?? 'سورة';
      lines.add(MushafLine([MushafToken(text: name)], center: true));
      if (surahId != 1 && surahId != 9) {
        lines.add(MushafLine([MushafToken(text: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ')], center: true));
      }
    }

    // Ensure verses are sorted correctly (surahNumber ASC, ayahNumber ASC)
    verses.sort((a, b) {
      if (a.surahId != b.surahId) {
        return a.surahId.compareTo(b.surahId);
      }
      return a.ayahNo.compareTo(b.ayahNo);
    });

    int? lastSurah;
    final markerSequence = <String>[]; // For debug
    
    for (final v in verses) {
      final isNewSurah = v.surahId != lastSurah && v.ayahNo == 1;
      if (isNewSurah) {
        flushLine();
        insertSurahHeader(v.surahId);
      }
      lastSurah = v.surahId;

      // Clean Arabic text: remove any existing ornament glyphs (\u06DD) that might be in the text
      final cleanedArabic = v.arabic.replaceAll('\u06DD', '').trim();
      final words = cleanedArabic.split(' ');
      for (final w in words) {
        if (w.trim().isEmpty) continue;
        tokens.add(MushafToken(text: '$w '));
      }
      // Create marker token with actual surahId and ayahNo (ONLY ONCE per verse)
      final markerToken = MushafToken(
        text: '${v.ayahNo}', // Keep text for backward compatibility
        isMarker: true,
        surahId: v.surahId,
        ayahNo: v.ayahNo,
      );
      tokens.add(markerToken);
      markerSequence.add('${v.surahId}:${v.ayahNo}');
    }

    // Debug: Print marker sequence for page 1 and 604
    if (pageNo == 1 || pageNo == 604) {
      debugPrint('=== PAGE $pageNo MARKER SEQUENCE (BEFORE BREAKING) ===');
      debugPrint('Total markers: ${markerSequence.length}');
      for (final marker in markerSequence) {
        debugPrint('  $marker');
      }
      debugPrint('========================================================');
    }

    final textStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: 'UthmanicHafsV22',
      fontFamilyFallback: const ['UthmanicHafs'],
      height: 1.6,
    );

    double measureToken(String text, {bool marker = false}) {
      if (marker) {
        // Measure badge as TextSpan with ornament glyph
        final badgeFontSize = fontSize * 0.65;
        final badgeText = ' \u06DD٠ '; // Use placeholder for measurement
        final badgeStyle = textStyle.copyWith(fontSize: badgeFontSize, height: 1.0);
        final tp = TextPainter(
          text: TextSpan(text: badgeText, style: badgeStyle),
          textDirection: TextDirection.rtl,
          maxLines: 1,
        )..layout();
        return tp.width;
      }
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.rtl,
        maxLines: 1,
      )..layout();
      return tp.width;
    }

    // Greedy line breaking with lookahead
    var current = <MushafToken>[];
    double currentWidth = 0;

    for (int i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      final w = measureToken(t.text, marker: t.isMarker);

      bool willOverflow = currentWidth + w > maxWidth;

      if (t.isMarker) {
        if (current.isEmpty && lines.isNotEmpty) {
          // attach to previous line if possible
          current.add(t);
          currentWidth += w;
          continue;
        }
        if (willOverflow && current.isNotEmpty) {
          // move previous token + marker to next line
          final prev = current.removeLast();
          currentWidth -= measureToken(prev.text, marker: prev.isMarker);
          lines.add(MushafLine(List.from(current)));
          current = [prev, t];
          currentWidth = measureToken(prev.text, marker: prev.isMarker) + w;
          continue;
        }
      }

      // C) Lookahead: Check if next line would be orphaned
      if (willOverflow && current.isNotEmpty) {
        // A) Check if current line ends with sticky token - must move to next line
        final lastCurrentToken = current.last;
        final currentEndsWithSticky = !lastCurrentToken.isMarker && 
                                      _isStickyToken(lastCurrentToken.text);
        
        // Tentatively build next line starting with current token
        final nextLineTokens = <MushafToken>[];
        double nextLineWidth = 0;
        
        // Add current token (which would start next line)
        nextLineTokens.add(t);
        nextLineWidth += w;
        
        // Add more tokens until line is full or we have enough to check
        for (int j = i + 1; j < tokens.length && j < i + 5; j++) {
          final nextToken = tokens[j];
          final nextW = measureToken(nextToken.text, marker: nextToken.isMarker);
          if (nextLineWidth + nextW > maxWidth) break;
          nextLineTokens.add(nextToken);
          nextLineWidth += nextW;
        }

        // Check if next line would be orphaned (very aggressive threshold)
        final nextWordCount = nextLineTokens.where((tok) => !tok.isMarker).length;
        final nextLineTooShort = nextLineWidth < maxWidth * 0.42; // Increased from 0.35
        final nextLineSingleWord = nextWordCount <= 1;
        final nextLineEndsWithSticky = nextLineTokens.isNotEmpty && 
                                       !nextLineTokens.last.isMarker &&
                                       _isStickyToken(nextLineTokens.last.text);
        
        // Also check if next line would have only 2-3 words (still too short)
        final nextLineTwoWords = nextWordCount == 2 && nextLineWidth < maxWidth * 0.45;
        final nextLineThreeWords = nextWordCount == 3 && nextLineWidth < maxWidth * 0.48;

        // If current line ends with sticky OR next line would be problematic, break earlier
        if (currentEndsWithSticky || nextLineTooShort || nextLineSingleWord || nextLineEndsWithSticky || nextLineTwoWords || nextLineThreeWords) {
          // Move last token from current line to next line
          if (current.length > 1) {
            final lastToken = current.removeLast();
            currentWidth -= measureToken(lastToken.text, marker: lastToken.isMarker);
            lines.add(MushafLine(List.from(current)));
            current = [lastToken, t];
            currentWidth = measureToken(lastToken.text, marker: lastToken.isMarker) + w;
            continue;
          }
        }

        // Normal break
        lines.add(MushafLine(List.from(current)));
        current = [];
        currentWidth = 0;
      }

      current.add(t);
      currentWidth += w;

      // Check sticky token rule: don't end line with sticky token
      if (!t.isMarker && _isStickyToken(t.text) && current.length > 1) {
        // If this sticky token would be last in current line, check if we should break earlier
        // This is handled by lookahead above, but also check current state
        if (i < tokens.length - 1 && !tokens[i + 1].isMarker) {
          // There's a next word, so sticky token won't be last - OK
        }
      }
    }
    if (current.isNotEmpty) {
      lines.add(MushafLine(current));
    }

    // Post-processing: Line balancing to prevent orphaned words
    final balancedLines = _balanceLines(lines, maxWidth, textStyle, measureToken);
    
    // Additional post-processing: Fix orphan short words
    final finalLines = _rebalanceLines(balancedLines, maxWidth, measureToken);

    // Debug: Print marker sequence after balancing for page 1 and 604
    if (pageNo == 1 || pageNo == 604) {
      debugPrint('=== PAGE $pageNo MARKER SEQUENCE (AFTER BALANCING) ===');
      final afterMarkers = <String>[];
      for (final line in finalLines) {
        for (final token in line.tokens) {
          if (token.isMarker && token.surahId != null && token.ayahNo != null) {
            afterMarkers.add('${token.surahId}:${token.ayahNo}');
          }
        }
      }
      debugPrint('Total markers: ${afterMarkers.length}');
      for (final marker in afterMarkers) {
        debugPrint('  $marker');
      }
      debugPrint('=========================================================');
    }

    return finalLines;
  }

  static List<MushafLine> _balanceLines(
    List<MushafLine> lines,
    double maxWidth,
    TextStyle textStyle,
    double Function(String, {bool marker}) measureToken,
  ) {
    if (lines.isEmpty) return lines;

    final orphanThreshold = maxWidth * 0.42; // 42% of maxWidth (hard constraint) - very aggressive
    final softGuardThreshold = maxWidth * 0.45; // 45% of maxWidth (soft guard)
    
    // Convert to mutable list for easier manipulation
    final balanced = lines.map((l) => List<MushafToken>.from(l.tokens)).toList();
    final centers = lines.map((l) => l.center).toList();
    
    int totalMoves = 0;
    const maxTotalMoves = 12; // Increased from 8 to allow more balancing
    int iterations = 0;
    const maxIterations = 80; // Increased from 50

    // Post-processing balancing across ALL lines
    while (iterations < maxIterations && totalMoves < maxTotalMoves) {
      bool changed = false;
      iterations++;

      // Process each adjacent pair (i-1, i)
      for (int i = 1; i < balanced.length; i++) {
        // Skip centered lines
        if (centers[i] || centers[i - 1]) continue;

        final tokens = balanced[i];
        if (tokens.isEmpty) continue;

        // Count word tokens (exclude markers)
        final wordTokens = tokens.where((t) => !t.isMarker).toList();
        final wordTokenCount = wordTokens.length;
        
        // Calculate line width
        double lineWidth = 0;
        for (final token in tokens) {
          lineWidth += measureToken(token.text, marker: token.isMarker);
        }

        // B) Strong orphan rule (hard constraint): single/two/three word tokens MUST be fixed
        final isOrphan = wordTokenCount <= 3 || lineWidth < orphanThreshold;
        
        // Check sticky token rule: line ending with sticky token
        final endsWithSticky = tokens.isNotEmpty && 
                               !tokens.last.isMarker &&
                               _isStickyToken(tokens.last.text);

        // Trigger rebalancing if orphan or sticky token violation
        if (isOrphan || endsWithSticky) {
          final prevTokens = balanced[i - 1];
          if (prevTokens.isEmpty) continue;

          // Calculate previous line width
          double prevWidth = 0;
          for (final token in prevTokens) {
            prevWidth += measureToken(token.text, marker: token.isMarker);
          }

          // Try to move tokens from previous line (1-2 moves)
          final tokensToMove = <MushafToken>[];
          double moveWidth = 0;
          int moves = 0;
          const maxMoves = 2;

          // Check if last token of previous line is a marker
          final lastTokenIsMarker = prevTokens.isNotEmpty && prevTokens.last.isMarker;
          
          if (lastTokenIsMarker && prevTokens.length >= 2 && moves < maxMoves) {
            // Move [word + marker] pair together
            final wordToken = prevTokens[prevTokens.length - 2];
            final markerToken = prevTokens.last;
            final pairWidth = measureToken(wordToken.text, marker: wordToken.isMarker) +
                            measureToken(markerToken.text, marker: markerToken.isMarker);
            
            // E) Soft guard: try to keep >= 32%, but allow below if orphan rule triggers
            final newPrevWidth = prevWidth - pairWidth;
            if (isOrphan || newPrevWidth >= softGuardThreshold) {
              tokensToMove.add(wordToken);
              tokensToMove.add(markerToken);
              moveWidth = pairWidth;
              moves++;
            }
          } else if (!lastTokenIsMarker && prevTokens.isNotEmpty && moves < maxMoves) {
            // Move last word token
            final lastToken = prevTokens.last;
            final tokenWidth = measureToken(lastToken.text, marker: lastToken.isMarker);
            
            // Check if it's a sticky token - don't move if it would create sticky at line end
            final isSticky = _isStickyToken(lastToken.text);
            if (!isSticky || tokens.isNotEmpty) {
              final newPrevWidth = prevWidth - tokenWidth;
              if (isOrphan || newPrevWidth >= softGuardThreshold) {
                tokensToMove.add(lastToken);
                moveWidth = tokenWidth;
                moves++;
              }
            }
          }

          // Try second move if needed and allowed
          if (moves < maxMoves && tokensToMove.isNotEmpty && prevTokens.length > tokensToMove.length) {
            final remainingPrevTokens = prevTokens.length - tokensToMove.length;
            if (remainingPrevTokens >= 2) {
              final checkIndex = prevTokens.length - tokensToMove.length - 1;
              final checkToken = prevTokens[checkIndex];
              final checkWidth = measureToken(checkToken.text, marker: checkToken.isMarker);
              final newPrevWidth = prevWidth - moveWidth - checkWidth;
              
              // Only move if it helps and doesn't violate soft guard too much
              if (isOrphan || newPrevWidth >= softGuardThreshold) {
                tokensToMove.insert(0, checkToken);
                moveWidth += checkWidth;
                moves++;
              }
            }
          }

          if (tokensToMove.isNotEmpty && totalMoves < maxTotalMoves) {
            // Remove tokens from previous line
            for (int j = 0; j < tokensToMove.length; j++) {
              balanced[i - 1].removeLast();
            }

            // Add tokens to current line at the START
            balanced[i].insertAll(0, tokensToMove);
            
            // Ensure marker never starts a line
            if (balanced[i].isNotEmpty && balanced[i].first.isMarker && !centers[i - 1]) {
              final markerToken = balanced[i].removeAt(0);
              balanced[i - 1].add(markerToken);
            }

            totalMoves++;
            changed = true;
          }
        }
      }

      if (!changed) break;
    }

    // Final pass: Fix sticky tokens at line end and orphan markers
    for (int i = 0; i < balanced.length; i++) {
      if (centers[i]) continue;
      
      final tokens = balanced[i];
      if (tokens.isEmpty) continue;
      
      // Fix sticky token at line end
      if (tokens.length > 1 && 
          !tokens.last.isMarker && 
          _isStickyToken(tokens.last.text) &&
          i < balanced.length - 1 && 
          !centers[i + 1]) {
        // Move sticky token to next line with next word
        final stickyToken = tokens.removeLast();
        if (balanced[i + 1].isNotEmpty) {
          balanced[i + 1].insert(0, stickyToken);
        }
      }
      
      // Fix marker at line start
      if (tokens.isNotEmpty && tokens.first.isMarker && i > 0 && !centers[i - 1]) {
        final markerToken = tokens.removeAt(0);
        balanced[i - 1].add(markerToken);
      }
    }

    // Convert back to MushafLine objects
    return balanced.asMap().entries.map((e) {
      return MushafLine(e.value, center: centers[e.key]);
    }).toList();
  }

  /// Additional post-processing: Fix orphan short words (PATCH 3)
  static List<MushafLine> _rebalanceLines(
    List<MushafLine> lines,
    double maxWidth,
    double Function(String, {bool marker}) measureToken,
  ) {
    if (lines.isEmpty) return lines;

    // Convert to mutable list
    final rebalanced = lines.map((l) => List<MushafToken>.from(l.tokens)).toList();
    final centers = lines.map((l) => l.center).toList();

    // Process each line pair
    for (int i = 1; i < rebalanced.length; i++) {
      if (centers[i] || centers[i - 1]) continue; // Skip centered lines

      final current = rebalanced[i];
      final prev = rebalanced[i - 1];

      if (current.isEmpty || prev.isEmpty) continue;

      final firstToken = current.first;

      // Check if should pull up: single token OR short Arabic word
      final shouldPullUp = current.length == 1 ||
          (!firstToken.isMarker && _isShortArabicWord(firstToken.text));

      if (shouldPullUp && prev.isNotEmpty) {
        // Move last token from previous line
        final moved = prev.removeLast();

        // If moved token is ayah badge, pull its paired word too
        if (moved.isMarker && prev.isNotEmpty) {
          final pairedWord = prev.removeLast();
          current.insert(0, pairedWord);
        }

        current.insert(0, moved);
      }
    }

    // Convert back to MushafLine objects
    return rebalanced.asMap().entries.map((e) {
      return MushafLine(e.value, center: centers[e.key]);
    }).toList();
  }

  static Future<List<PageRange>> _pageRanges(int pageNo) async {
    final data = await rootBundle.loadString('assets/quran/index_pages.json');
    final map = jsonDecode(data) as Map<String, dynamic>;
    final list = map['$pageNo'] as List<dynamic>;
    return list.map((e) => PageRange.fromJson(e as Map<String, dynamic>)).toList();
  }
}

