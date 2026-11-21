import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/reader_source.dart';
import 'package:quran_offline/core/providers/completed_reading_provider.dart';
import 'package:quran_offline/core/providers/last_read_location_provider.dart';
import 'package:quran_offline/core/providers/last_read_progress_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/surah_names_provider.dart';
import 'package:quran_offline/features/read/widgets/last_read_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// While a reader route covers Home, saving the last read page on every page
/// turn must not rebuild the hidden Home card: its new text re-laid out the
/// whole hidden Home (every tab and list) twice per turn (issue #25).
void main() {
  testWidgets('Home card stays put while covered and catches up on return',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'language': 'id',
      'appLanguage': 'id',
      'last_read_position_type': 'page',
      'last_read_position_id': 3,
      'last_read_position_timestamp': '2026-11-09T10:00:00.000',
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lastReadLocationProvider.overrideWith((ref) async {
            final lastRead = ref.watch(lastReadProvider);
            if (lastRead == null) return null;
            return LastReadLocation(type: 'page', pageNo: lastRead.id);
          }),
          lastReadProgressProvider.overrideWith((ref) async => null),
          continueCompletionProvider.overrideWith((ref) async => null),
          surahNamesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: Scaffold(body: LastReadCard(forHome: true)),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
    expect(find.text('Halaman 3'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(LastReadCard)),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('reader')),
      ),
    );
    await tester.pumpAndSettle();

    await container
        .read(lastReadProvider.notifier)
        .saveLastRead(const PageSource(5));
    await tester.pump();
    await container
        .read(lastReadProvider.notifier)
        .saveLastRead(const PageSource(6));
    await tester.pumpAndSettle();
    expect(
      find.text('Halaman 3', skipOffstage: false),
      findsOneWidget,
      reason: 'the covered card is not rebuilt for each saved page',
    );
    expect(find.text('Halaman 6', skipOffstage: false), findsNothing);

    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('Halaman 6'), findsOneWidget);
  });
}
