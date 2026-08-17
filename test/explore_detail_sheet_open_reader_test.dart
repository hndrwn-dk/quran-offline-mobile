import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/explore_detail_sheet.dart';

void main() {
  final surahNames = [
    SurahInfo(
      id: 17,
      arabicName: 'الإسراء',
      englishName: 'Al-Isra',
      englishMeaning: 'The Night Journey',
    ),
    SurahInfo(
      id: 31,
      arabicName: 'لقمان',
      englishName: 'Luqman',
      englishMeaning: 'Luqman',
    ),
  ];

  testWidgets('openReaderFromAyahRef targets the chosen surah and ayah', (
    tester,
  ) async {
    late WidgetRef widgetRef;
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            widgetRef = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    openReaderFromAyahRef(
      widgetRef,
      const DuaAyahRef(surah: 31, from: 14, to: 14),
    );

    final source = widgetRef.read(readerSourceProvider);
    expect(source, isA<SurahSource>());
    final surahSource = source as SurahSource;
    expect(surahSource.surahId, 31);
    expect(surahSource.targetAyahNo, 14);
    expect(widgetRef.read(targetAyahProvider), 14);
  });

  test('exploreAyahRefPickerLabel includes surah name and QS ref', () {
    final label = exploreAyahRefPickerLabel(
      const DuaAyahRef(surah: 17, from: 24, to: 24),
      'id',
      surahNames,
    );
    expect(label, 'Al-Isra · QS 17:24');
  });

  testWidgets(
    'single ayahRef opens Reader for that ref without a picker',
    (tester) async {
      DuaAyahRef? opened;
      await tester.pumpWidget(
        _harness(
          surahNames: surahNames,
          ayahRefs: const [DuaAyahRef(surah: 17, from: 24, to: 24)],
          onOpenReader: (ref) => opened = ref,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(opened?.surah, 17);
      expect(opened?.from, 24);
      expect(opened?.to, 24);
      expect(find.text(AppLocalizations.getExploreChooseAyah('id')), findsNothing);
    },
  );

  testWidgets(
    'multiple ayahRefs show a picker; choosing second opens that ref',
    (tester) async {
      DuaAyahRef? opened;
      await tester.pumpWidget(
        _harness(
          surahNames: surahNames,
          ayahRefs: const [
            DuaAyahRef(surah: 17, from: 24, to: 24),
            DuaAyahRef(surah: 31, from: 14, to: 14),
          ],
          onOpenReader: (ref) => opened = ref,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(opened, isNull);
      expect(find.text(AppLocalizations.getExploreChooseAyah('id')), findsOneWidget);
      expect(find.text('Al-Isra · QS 17:24'), findsOneWidget);
      expect(find.text('Luqman · QS 31:14'), findsOneWidget);

      await tester.tap(find.text('Luqman · QS 31:14'));
      await tester.pumpAndSettle();

      expect(opened?.surah, 31);
      expect(opened?.from, 14);
      expect(opened?.to, 14);
    },
  );
}

Widget _harness({
  required List<SurahInfo> surahNames,
  required List<DuaAyahRef> ayahRefs,
  required void Function(DuaAyahRef) onOpenReader,
}) {
  return ProviderScope(
    overrides: [
      surahNamesProvider.overrideWith((ref) async => surahNames),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ExploreDetailSheet(
          title: const LocalizedText(
            id: 'Judul',
            en: 'Title',
            zh: 'Title',
            ja: 'Title',
          ),
          summary: const LocalizedText(
            id: 'Ringkasan',
            en: 'Summary',
            zh: 'Summary',
            ja: 'Summary',
          ),
          ayahRefs: ayahRefs,
          lang: 'id',
          onOpenReader: onOpenReader,
        ),
      ),
    ),
  );
}
