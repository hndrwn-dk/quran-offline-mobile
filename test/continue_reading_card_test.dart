import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/last_read_location_provider.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/read/widgets/last_read_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpHomeCard(
  WidgetTester tester, {
  required Map<String, Object> lastReadPrefs,
  required LastReadLocation location,
  LastReadProgress? progress,
  List<SurahInfo>? surahs,
  String language = 'id',
  double textScale = 1.0,
  bool scrollable = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'language': language,
    'appLanguage': language,
    ...lastReadPrefs,
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lastReadLocationProvider.overrideWith((ref) async => location),
        lastReadProgressProvider.overrideWith((ref) async => progress),
        surahNamesProvider.overrideWith(
          (ref) async =>
              surahs ??
              [
                SurahInfo(
                  id: 2,
                  arabicName: '',
                  englishName: 'Al-Baqarah',
                  englishMeaning: 'The Cow',
                ),
              ],
        ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: scrollable
              ? const SingleChildScrollView(child: LastReadCard(forHome: true))
              : const LastReadCard(forHome: true),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

Map<String, Object> _prefs({
  required String type,
  required int id,
  int? ayahNo,
  int? surahId,
}) {
  return {
    'last_read_position_type': type,
    'last_read_position_id': id,
    if (ayahNo != null) 'last_read_position_ayahNo': ayahNo,
    if (surahId != null) 'last_read_position_surahId': surahId,
    'last_read_position_timestamp': DateTime.now().toIso8601String(),
  };
}

void main() {
  test('page progress uses the juz page range', () {
    expect(
      pageProgressInJuz(pageNo: 20, startPage: 1, endPage: 21),
      closeTo(20 / 21, 1e-9),
    );
    expect(
      pageProgressInJuz(pageNo: 22, startPage: 22, endPage: 41),
      closeTo(1 / 20, 1e-9),
    );
    expect(
      pageProgressInJuz(pageNo: 41, startPage: 22, endPage: 41),
      1.0,
    );
    expect(
      pageProgressInJuz(pageNo: 20, startPage: null, endPage: 21),
      isNull,
    );
  });

  testWidgets('surah card shows ayah detail and percentage', (tester) async {
    await _pumpHomeCard(
      tester,
      lastReadPrefs: _prefs(type: 'surah', id: 2, ayahNo: 2),
      location: const LastReadLocation(
        type: 'surah',
        surahId: 2,
        ayahNo: 2,
        juzNo: 1,
      ),
      progress: const LastReadProgress(
        fraction: 2 / 7,
        scope: 'surah',
        current: 2,
        total: 7,
      ),
    );

    expect(find.text('Al-Baqarah'), findsOneWidget);
    expect(find.text('Ayat 2 dari 7 · Juz 1'), findsOneWidget);
    expect(find.text('28%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('juz card shows the juz unit, not a mixed scope', (tester) async {
    await _pumpHomeCard(
      tester,
      lastReadPrefs: _prefs(type: 'juz', id: 1, ayahNo: 12, surahId: 2),
      location: const LastReadLocation(
        type: 'juz',
        surahId: 2,
        ayahNo: 12,
        juzNo: 1,
      ),
      progress: const LastReadProgress(
        fraction: 12 / 148,
        scope: 'juz',
        current: 12,
        total: 148,
      ),
    );

    expect(find.text('Juz 1'), findsOneWidget);
    expect(find.text('Al-Baqarah ayat 12 · 12 dari 148 ayat'), findsOneWidget);
    expect(find.text('8%'), findsOneWidget);
  });

  testWidgets('An-Naba 78:6 in juz mode keeps surah ayah and juz index apart', (
    tester,
  ) async {
    await _pumpHomeCard(
      tester,
      lastReadPrefs: _prefs(type: 'juz', id: 30, ayahNo: 6, surahId: 78),
      location: const LastReadLocation(
        type: 'juz',
        surahId: 78,
        ayahNo: 6,
        juzNo: 30,
      ),
      progress: const LastReadProgress(
        fraction: 6 / 564,
        scope: 'juz',
        current: 6,
        total: 564,
      ),
      surahs: [
        SurahInfo(
          id: 78,
          arabicName: '',
          englishName: 'An-Naba',
          englishMeaning: 'The Tidings',
        ),
      ],
    );

    expect(find.text('Juz 30 (Juz Amma)'), findsOneWidget);
    expect(find.text('An-Naba ayat 6 · 6 dari 564 ayat'), findsOneWidget);
    expect(find.text('1%'), findsOneWidget);
  });

  testWidgets('An-Nazi\'at 79:3 in juz mode uses the juz index, not the ayah', (
    tester,
  ) async {
    await _pumpHomeCard(
      tester,
      lastReadPrefs: _prefs(type: 'juz', id: 30, ayahNo: 3, surahId: 79),
      location: const LastReadLocation(
        type: 'juz',
        surahId: 79,
        ayahNo: 3,
        juzNo: 30,
      ),
      progress: const LastReadProgress(
        fraction: 43 / 564,
        scope: 'juz',
        current: 43,
        total: 564,
      ),
      surahs: [
        SurahInfo(
          id: 79,
          arabicName: '',
          englishName: 'An-Nazi\'at',
          englishMeaning: 'Those Who Drag Forth',
        ),
      ],
    );

    expect(find.text('Juz 30 (Juz Amma)'), findsOneWidget);
    expect(find.text('An-Nazi\'at ayat 3 · 43 dari 564 ayat'), findsOneWidget);
    expect(find.text('7%'), findsOneWidget);
  });

  testWidgets('mushaf card uses the page unit and the surah name', (
    tester,
  ) async {
    await _pumpHomeCard(
      tester,
      lastReadPrefs: _prefs(type: 'page', id: 20, ayahNo: 153, surahId: 2),
      location: const LastReadLocation(
        type: 'page',
        surahId: 2,
        ayahNo: 153,
        pageNo: 20,
        juzNo: 1,
        juzStartPage: 1,
        juzEndPage: 21,
      ),
    );

    expect(find.text('Halaman 20'), findsOneWidget);
    expect(find.text('Al-Baqarah · Juz 1 · hal. 20 dari 21'), findsOneWidget);
    expect(find.text('95%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('continue card keeps the pill compact and a ring', (
    tester,
  ) async {
    await _pumpHomeCard(
      tester,
      lastReadPrefs: _prefs(type: 'surah', id: 2, ayahNo: 2),
      location: const LastReadLocation(
        type: 'surah',
        surahId: 2,
        ayahNo: 2,
        juzNo: 1,
      ),
      progress: const LastReadProgress(
        fraction: 2 / 7,
        scope: 'surah',
        current: 2,
        total: 7,
      ),
    );

    final cardWidth = tester.getSize(find.byType(LastReadCard)).width;
    final pill = tester.getSize(
      find
          .ancestor(
            of: find.text(AppLocalizations.getHomeContinuePill('id')),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(pill.width, lessThan(cardWidth * 0.6));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('the whole card is tappable, not only the arrow', (tester) async {
    await _pumpHomeCard(
      tester,
      lastReadPrefs: _prefs(type: 'surah', id: 2, ayahNo: 2),
      location: const LastReadLocation(
        type: 'surah',
        surahId: 2,
        ayahNo: 2,
        juzNo: 1,
      ),
      progress: const LastReadProgress(
        fraction: 2 / 7,
        scope: 'surah',
        current: 2,
        total: 7,
      ),
    );

    final titleInk = tester.widget<InkWell>(
      find
          .ancestor(
            of: find.text('Al-Baqarah'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    final detailInk = tester.widget<InkWell>(
      find
          .ancestor(
            of: find.text('Ayat 2 dari 7 · Juz 1'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(titleInk.onTap, isNotNull);
    expect(identical(titleInk.onTap, detailInk.onTap), isTrue);
  });

  testWidgets('the ring exposes percent and scope to screen readers', (
    tester,
  ) async {
    await _pumpHomeCard(
      tester,
      lastReadPrefs: _prefs(type: 'surah', id: 2, ayahNo: 2),
      location: const LastReadLocation(
        type: 'surah',
        surahId: 2,
        ayahNo: 2,
        juzNo: 1,
      ),
      progress: const LastReadProgress(
        fraction: 2 / 7,
        scope: 'surah',
        current: 2,
        total: 7,
      ),
    );

    final semanticsWidget = tester.widget<Semantics>(
      find.byKey(const ValueKey('continue_progress_semantics')),
    );
    expect(semanticsWidget.properties.label, 'Progress surah, 28%');
  });
  testWidgets('Juz Amma title fits at max text scale in ZH', (tester) async {
    await _pumpHomeCard(
      tester,
      language: 'zh',
      textScale: 2.0,
      scrollable: true,
      lastReadPrefs: _prefs(type: 'juz', id: 30, ayahNo: 6, surahId: 78),
      location: const LastReadLocation(
        type: 'juz',
        surahId: 78,
        ayahNo: 6,
        juzNo: 30,
      ),
      progress: const LastReadProgress(
        fraction: 6 / 564,
        scope: 'juz',
        current: 6,
        total: 564,
      ),
      surahs: [
        SurahInfo(
          id: 78,
          arabicName: '',
          englishName: 'An-Naba',
          englishMeaning: 'The Tidings',
        ),
      ],
    );

    expect(find.text('第 30 卷（阿玛章）'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Juz Amma title fits at max text scale in JA', (tester) async {
    await _pumpHomeCard(
      tester,
      language: 'ja',
      textScale: 2.0,
      scrollable: true,
      lastReadPrefs: _prefs(type: 'juz', id: 30, ayahNo: 6, surahId: 78),
      location: const LastReadLocation(
        type: 'juz',
        surahId: 78,
        ayahNo: 6,
        juzNo: 30,
      ),
      progress: const LastReadProgress(
        fraction: 6 / 564,
        scope: 'juz',
        current: 6,
        total: 564,
      ),
      surahs: [
        SurahInfo(
          id: 78,
          arabicName: '',
          englishName: 'An-Naba',
          englishMeaning: 'The Tidings',
        ),
      ],
    );

    expect(find.text('第 30 ジュズ（ジュズ・アンマー）'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
