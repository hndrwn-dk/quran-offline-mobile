import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/core/database/database.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/share/verse_share_card.dart';
import 'package:quran_offline/core/share/verse_share_content.dart';

Verse _verse({
  required int surahId,
  required int ayahNo,
  required String arabic,
}) {
  return Verse(
    surahId: surahId,
    ayahNo: ayahNo,
    page: 1,
    juz: 1,
    arabic: arabic,
    trId: 'Terjemahan',
  );
}

void main() {
  final settings = AppSettings(
    language: 'id',
    appLanguage: 'id',
  );

  VerseShareContent sampleContent() {
    return VerseShareContent.from(
      verse: _verse(
        surahId: 52,
        ayahNo: 21,
        arabic: 'وَالَّذِينَ آمَنُوا',
      ),
      surahName: 'At-Tur',
      settings: settings,
    );
  }

  testWidgets('share card uses dark text on light backdrop when app is dark', (tester) async {
    final lightOnSurface = AppColors.lightColorScheme().onSurface;
    final darkOnSurface = AppColors.darkColorScheme().onSurface;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: AppColors.darkColorScheme(),
        ),
        home: Scaffold(
          body: Center(
            child: VerseShareCard(content: sampleContent()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final header = tester.widget<Text>(find.text('Quran Offline'));
    final headerColor = header.style?.color;
    expect(headerColor, isNotNull);
    expect(
      headerColor!.computeLuminance(),
      lessThan(darkOnSurface.computeLuminance()),
      reason: 'Header should use light-theme onSurface, not dark-theme onSurface',
    );
    expect(
      headerColor.computeLuminance(),
      closeTo(lightOnSurface.computeLuminance(), 0.01),
    );
  });
}
