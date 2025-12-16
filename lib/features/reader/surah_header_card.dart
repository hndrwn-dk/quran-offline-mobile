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
          // Latin name (hero)
          Text(
            surahInfo.englishName,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.6,
                  fontSize: 28,
                ),
          ),
          const SizedBox(height: 6),
          // Arabic name (hero) - larger size
          Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                surahInfo.arabicName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'UthmanicHafsV22',
                      fontFamilyFallback: const ['UthmanicHafs'],
                      height: 1.4,
                      color: colorScheme.onSurface,
                      fontSize: 34,
                    ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
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

