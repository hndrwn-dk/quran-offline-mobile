import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';

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
}
