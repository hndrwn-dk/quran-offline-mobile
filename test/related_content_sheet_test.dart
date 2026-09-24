import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/ai_search/search_index_repository.dart';
import 'package:quran_offline/core/providers/ai_search_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/reader/widgets/related_content_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIndex extends SearchIndexRepository {
  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<String>> relatedDocIds(int surah, int ayah) async {
    expect(surah, 2);
    expect(ayah, 1);
    return [
      'ayah:2:1:id',
      'dua:one:id',
      'theme:patience:id',
      'asma:17:id',
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('related sheet groups fixture docs by type', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchIndexRepositoryProvider.overrideWith((ref) => _FakeIndex()),
        ],
        child: const MaterialApp(
          home: RelatedContentSheet(surah: 2, ayah: 1, lang: 'id'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizations.getRelatedContentTitle('id')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('related_group_dua')), findsOneWidget);
    expect(find.byKey(const Key('related_group_theme')), findsOneWidget);
    expect(find.byKey(const Key('related_group_asma')), findsOneWidget);
    expect(find.byKey(const Key('related_group_ayah')), findsNothing);
    expect(find.byType(Card), findsNWidgets(3));
  });

  test('parses related doc ids without inventing similarity scores', () {
    final hits = relatedHitsFromDocIds(
      [
        'ayah:2:1:id',
        'qdua:qd_003:id',
        'sci:earth1:id',
        'tafsir:id:2:1',
      ],
      surah: 2,
      ayah: 1,
    );
    expect(hits.map((h) => h.type), ['quran_dua', 'science', 'tafsir']);
    expect(hits.every((h) => h.score == 1.0), isTrue);
  });
}
