import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/features/read/widgets/weekly_reflection_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home card shows summary then reflection without context label', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const summary = LocalizedText(
      id: 'Ringkasan ayat',
      en: 'Verse summary',
      zh: 'Verse summary',
      ja: 'Verse summary',
    );
    const reflection = LocalizedText(
      id: 'Baca sebagian hari ini',
      en: 'A little reading is enough today',
      zh: 'A little reading is enough today',
      ja: 'A little reading is enough today',
    );
    final pick = ReflectionPick(
      entry: ReflectionLensEntry(
        id: 'jumat_kahf',
        sort: 0,
        priority: 50,
        badgeKey: 'friday',
        title: const LocalizedText(
          id: 'Al-Kahf',
          en: 'Al-Kahf',
          zh: 'Al-Kahf',
          ja: 'Al-Kahf',
        ),
        summary: summary,
        reflection: reflection,
        ayahRefs: const [DuaAyahRef(surah: 18, from: 1, to: 10)],
        trigger: const ReflectionTrigger(type: 'weekday', weekday: 5),
      ),
      source: ReflectionPickSource.calendar,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reflectionPickProvider.overrideWith((ref) async => pick),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WeeklyReflectionCard(forHome: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Konteks singkat'), findsNothing);
    expect(find.text('Quick context'), findsNothing);
    expect(find.text('Verse summary'), findsOneWidget);

    final reflectionText = tester.widget<Text>(
      find.text('A little reading is enough today'),
    );
    expect(reflectionText.maxLines, 2);
    expect(reflectionText.overflow, TextOverflow.ellipsis);
    expect(reflectionText.style?.color, const Color(0xFF5F6459));
  });
}
