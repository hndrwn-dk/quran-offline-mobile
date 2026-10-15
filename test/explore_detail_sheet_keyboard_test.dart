import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/explore/explore_favorite.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'ExploreDetailSheet shrink-wraps under a short maxBodyHeight without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      FlutterError? overflow;
      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) {
          overflow = FlutterError(details.exceptionAsString());
        }
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: ExploreDetailSheet(
                  maxBodyHeight: 120,
                  title: const LocalizedText(
                    id: 'Maha Pembuat Perhitungan',
                    en: 'The Reckoner',
                    zh: 'The Reckoner',
                    ja: 'The Reckoner',
                  ),
                  summary: const LocalizedText(
                    id: 'Ringkasan.',
                    en: 'Summary.',
                    zh: 'Summary.',
                    ja: 'Summary.',
                  ),
                  ayahRefs: const [
                    DuaAyahRef(surah: 11, from: 6, to: 6),
                  ],
                  headerArabic: 'الحسيب',
                  lang: 'id',
                  onOpenReader: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(overflow, isNull, reason: overflow?.message);
      expect(tester.takeException(), isNull);
      expect(find.byType(ExploreDetailSheet), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    },
  );

  testWidgets('detail sheet hugs its content instead of filling the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ExploreDetailSheet(
                title: const LocalizedText(
                  id: 'Pasangan',
                  en: 'Pairs',
                  zh: 'Pairs',
                  ja: 'Pairs',
                ),
                summary: const LocalizedText(
                  id: 'Ringkas.',
                  en: 'Short.',
                  zh: 'Short.',
                  ja: 'Short.',
                ),
                ayahRefs: const [],
                lang: 'id',
                onOpenReader: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
        tester.getSize(find.byType(ExploreDetailSheet)).height, lessThan(500));
  });

  testWidgets('save notice stays inside a content-sized sheet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ExploreDetailSheet(
                title: const LocalizedText(
                  id: 'Pasangan',
                  en: 'Pairs',
                  zh: 'Pairs',
                  ja: 'Pairs',
                ),
                summary: const LocalizedText(
                  id: 'Ringkas.',
                  en: 'Short.',
                  zh: 'Short.',
                  ja: 'Short.',
                ),
                ayahRefs: const [],
                lang: 'id',
                favoriteKind: ExploreFavoriteKind.science,
                favoriteId: 'pairs',
                onOpenReader: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Disimpan ke Favorit'), findsOneWidget);
    expect(find.text('Lihat'), findsOneWidget);
    expect(
        tester.getSize(find.byType(ExploreDetailSheet)).height, lessThan(500));

    await tester.pump(const Duration(seconds: 4));
  });
}
