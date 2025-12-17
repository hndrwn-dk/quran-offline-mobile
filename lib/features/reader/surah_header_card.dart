import 'package:flutter/material.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';

class SurahHeaderCard extends StatelessWidget {
  final SurahInfo surahInfo;
  final int verseCount;

  const SurahHeaderCard({
    super.key,
    required this.surahInfo,
    required this.verseCount,
  });

  static bool _isMeccan(int surahId) {
    // Meccan surahs: 1-5, 6-7, 10-32, 34-46, 50-56, 67-96, 100-114
    // Medinan surahs: 2-3, 4-5, 8-9, 13, 22, 24, 33, 47-49, 57-66, 98
    final medinanSurahs = {
      2, 3, 4, 5, 8, 9, 13, 22, 24, 33, 47, 48, 49, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 98
    };
    return !medinanSurahs.contains(surahId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMeccan = _isMeccan(surahInfo.id);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row untuk sejajarkan Latin dan Arabic name
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // Latin name (hero) - tetap seperti semula
              Expanded(
                child: Text(
                  surahInfo.englishName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.6,
                        fontSize: 28,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              // Arabic name (Suratul format) - styling sama dengan Mushaf mode
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  surahInfo.arabicName,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'UthmanicHafsV22',
                        fontFamilyFallback: const ['UthmanicHafs'],
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        height: 1.7,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: colorScheme.primary.withOpacity(
                              Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.12,
                            ),
                            offset: const Offset(0, 1.5),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Meta row: Meccan/Medinan + verse count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isMeccan
                      ? colorScheme.primaryContainer.withOpacity(0.65)
                      : colorScheme.secondaryContainer.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isMeccan ? 'Meccan' : 'Medinan',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isMeccan
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$verseCount verses',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

