import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/ai_search/doa_need_resolver.dart';
import 'package:quran_offline/core/ai_search/search_index_repository.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/dua/doa_need_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

IndexHit _hit(String id, String type) {
  return IndexHit(
    docId: id,
    type: type,
    lang: 'id',
    refKey: id,
    surah: 2,
    ayahFrom: 1,
    ayahTo: 1,
    score: 1.0,
  );
}

DoaNeedItem _item(DoaNeedTier tier, String id, String type) {
  return DoaNeedItem(tier: tier, hit: _hit(id, type), score: 1.0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders each doa-need tier header', (tester) async {
    final preview = DoaNeedResult(
      tier1: [_item(DoaNeedTier.duaCatalog, 'dua:one', 'dua')],
      tier2: [_item(DoaNeedTier.quranDua, 'qdua:two', 'quran_dua')],
      tier3: [_item(DoaNeedTier.relatedAyah, 'ayah:2:1', 'ayah')],
      tier3b: [_item(DoaNeedTier.asma, 'asma:17', 'asma')],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: DoaNeedScreen(previewResult: preview),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('doa_need_header_tier1')), findsOneWidget);
    expect(find.byKey(const Key('doa_need_header_tier2')), findsOneWidget);
    expect(find.byKey(const Key('doa_need_header_tier3')), findsOneWidget);
    expect(find.byKey(const Key('doa_need_header_tier3b')), findsOneWidget);
    expect(
      find.text(AppLocalizations.getDoaNeedTier3Header('en')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('doa_need_header_tier4')), findsNothing);
  });

  testWidgets('empty result shows tier 4 copy', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DoaNeedScreen(previewResult: DoaNeedResult.empty),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('doa_need_header_tier4')), findsOneWidget);
    expect(find.text(AppLocalizations.getDoaNeedEmpty('en')), findsOneWidget);
  });

  test('new doa need dart files contain no Arabic literals', () {
    const arabic = r'[\u0600-\u06FF]';
    final files = [
      File('lib/features/dua/doa_need_screen.dart'),
      File('test/doa_need_screen_test.dart'),
    ];
    for (final file in files) {
      expect(
        RegExp(arabic).hasMatch(file.readAsStringSync()),
        isFalse,
        reason: file.path,
      );
    }
  });
}
