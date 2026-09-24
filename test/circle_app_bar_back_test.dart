import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/features/home/widgets/home_cta_buttons.dart';
import 'package:quran_offline/features/settings/widgets/settings_menu_app_bar.dart';

void main() {
  testWidgets('pushed screen back uses the Beranda circle arrow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        appBar: SettingsMenuAppBar(),
                        body: SizedBox.expand(),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsNothing);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byType(HomeCircleArrowButton), findsOneWidget);
  });

  testWidgets('circle back keeps a primary icon on a dark app bar', (tester) async {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5A7358),
      brightness: Brightness.dark,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Theme(
                        data: ThemeData(colorScheme: scheme),
                        child: const Scaffold(
                          appBar: SettingsMenuAppBar(),
                          body: SizedBox.expand(),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_back_rounded));
    expect(icon.color, scheme.primary);
  });
}
