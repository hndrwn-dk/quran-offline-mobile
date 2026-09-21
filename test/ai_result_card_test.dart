import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/search/widgets/ai_result_card.dart';

void main() {
  testWidgets('shows type label, source ref, and kurasi badge for science', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiResultCard(
            typeLabel: 'Sains',
            title: 'Catalog title from source',
            sourceRef: 'QS 2:164',
            showKurasiBadge: true,
            kurasiBadgeLabel: 'Penjelasan kurasi',
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('ai_result_type')), findsOneWidget);
    expect(find.text('Sains'), findsOneWidget);
    expect(find.text('Catalog title from source'), findsOneWidget);
    expect(find.byKey(const Key('ai_result_source')), findsOneWidget);
    expect(find.text('QS 2:164'), findsOneWidget);
    expect(find.byKey(const Key('ai_kurasi_badge')), findsOneWidget);
    expect(find.text('Penjelasan kurasi'), findsOneWidget);
  });

  testWidgets('hides kurasi badge for ayah and keeps source ref', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiResultCard(
            typeLabel: 'Ayat',
            title: 'Translation from verses table',
            sourceRef: 'QS 2:201',
            showKurasiBadge: false,
          ),
        ),
      ),
    );

    expect(find.text('Ayat'), findsOneWidget);
    expect(find.text('QS 2:201'), findsOneWidget);
    expect(find.byKey(const Key('ai_kurasi_badge')), findsNothing);
  });

  test('kurasi badge applies only to science and theme', () {
    expect(aiSearchShowsKurasiBadge('science'), isTrue);
    expect(aiSearchShowsKurasiBadge('theme'), isTrue);
    expect(aiSearchShowsKurasiBadge('ayah'), isFalse);
    expect(aiSearchShowsKurasiBadge('dua'), isFalse);
  });

  test('source refs follow R6 in all four languages', () {
    expect(
      AppLocalizations.formatDuaAyahRef(2, 201, 201, 'id'),
      'QS 2:201',
    );
    expect(
      AppLocalizations.getAiSearchTafsirSource('id', 2, 201),
      "Tafsir As-Sa'di 2:201",
    );
    expect(
      AppLocalizations.getAiSearchAsmaSource('en', '17'),
      'Names of Allah #17',
    );
    expect(
      AppLocalizations.getAiSearchKurasiBadge('id'),
      'Penjelasan kurasi',
    );
    expect(AppLocalizations.getAiSearchHeading('id'), "Tanya Al-Qur'an");
    for (final lang in ['id', 'en', 'zh', 'ja']) {
      expect(AppLocalizations.getAiSearchTypeLabel('ayah', lang), isNotEmpty);
      expect(AppLocalizations.getAiSearchKurasiBadge(lang), isNotEmpty);
    }
  });
}
