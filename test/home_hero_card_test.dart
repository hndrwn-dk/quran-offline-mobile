import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_colors.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/home/widgets/home_hero_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _arabic = RegExp(r'[\u0600-\u06FF]');

ReflectionPick _fixturePick() {
  const text = LocalizedText(
    id: 'Teks',
    en: 'Text',
    zh: 'Text',
    ja: 'Text',
  );
  return const ReflectionPick(
    entry: ReflectionLensEntry(
      id: 'jumat_kahf',
      sort: 0,
      priority: 50,
      badgeKey: 'friday',
      title: text,
      summary: text,
      reflection: text,
      ayahRefs: [DuaAyahRef(surah: 18, from: 1, to: 10)],
      trigger: ReflectionTrigger(type: 'weekday', weekday: 5),
    ),
    source: ReflectionPickSource.calendar,
  );
}

Future<ColorScheme> _pumpHero(
  WidgetTester tester, {
  required String language,
  Brightness brightness = Brightness.light,
}) async {
  SharedPreferences.setMockInitialValues({
    'language': language,
    'appLanguage': language,
  });
  final scheme = brightness == Brightness.dark
      ? AppColors.darkColorScheme()
      : AppColors.lightColorScheme();

  await tester.pumpWidget(
    ProviderScope(
      key: ValueKey('$language-${brightness.name}'),
      overrides: [
        reflectionNowProvider.overrideWithValue(DateTime(2026, 11, 1, 20)),
        reflectionPickProvider.overrideWith((ref) async => _fixturePick()),
      ],
      child: MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: const Scaffold(body: HomeHeroCard()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return scheme;
}

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  testWidgets('greeting shows the Hijri eyebrow and the salam', (tester) async {
    final scheme = await _pumpHero(tester, language: 'id');

    expect(
      find.text('MALAM SENIN · 22 JUMADIL AWAL 1448'),
      findsOneWidget,
    );
    expect(find.text('Assalamu\'alaikum'), findsOneWidget);

    final eyebrow = tester.widget<Text>(
      find.text('MALAM SENIN · 22 JUMADIL AWAL 1448'),
    );
    expect(eyebrow.style?.color, scheme.secondary);
    expect(eyebrow.style?.letterSpacing, 1.2);
    expect(eyebrow.style?.fontSize, 12);
    expect(eyebrow.style?.fontWeight, FontWeight.w600);

    final salam = tester.widget<Text>(find.text('Assalamu\'alaikum'));
    expect(salam.style?.color, scheme.onSurface);
    expect(salam.style?.fontSize, 26);
    expect(salam.style?.letterSpacing, -0.5);
  });

  testWidgets('greeting has no Arabic fragment, tagline, or card box', (
    tester,
  ) async {
    await _pumpHero(tester, language: 'id');

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && _arabic.hasMatch(widget.data ?? ''),
      ),
      findsNothing,
    );
    expect(find.textContaining('Hati yang tenang dekat dengan Qur'), findsNothing);
    expect(find.textContaining('Qur\'an di genggaman'), findsNothing);
    expect(find.textContaining('ٱلسَّلَامُ'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(HomeHeroCard),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('Chinese and Japanese keep the date as-is without tracking', (
    tester,
  ) async {
    final zhScheme = await _pumpHero(tester, language: 'zh');
    final zhEyebrow = tester.widget<Text>(
      find.textContaining('星期一前夜 · 22'),
    );
    expect(zhEyebrow.style?.letterSpacing, 0);
    expect(zhEyebrow.style?.color, zhScheme.secondary);

    await _pumpHero(tester, language: 'ja');
    final jaEyebrow = tester.widget<Text>(
      find.textContaining('月曜日の前夜 · 22'),
    );
    expect(jaEyebrow.style?.letterSpacing, 0);
    expect(jaEyebrow.data!.contains('月曜日'), isTrue);
  });

  testWidgets('English eyebrow is uppercase and tracked', (tester) async {
    await _pumpHero(tester, language: 'en');

    final eyebrow = tester.widget<Text>(
      find.textContaining('EVE OF MONDAY · 22 JUMADA AL-ULA 1448'),
    );
    expect(eyebrow.style?.letterSpacing, 1.2);
  });

  test('eyebrow green meets 4.5:1 on the home backdrop in both modes', () {
    for (final scheme in [
      AppColors.lightColorScheme(),
      AppColors.darkColorScheme(),
    ]) {
      final background = HomeBackdrop.topTint(scheme);
      expect(
        _contrast(scheme.secondary, background),
        greaterThanOrEqualTo(4.5),
        reason: '${scheme.brightness.name} eyebrow contrast',
      );
    }
  });
}
