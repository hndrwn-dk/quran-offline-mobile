import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/widgets/nav_read_icon.dart';

void main() {
  testWidgets('resolveLogicalSize is shared by precache and layer render size',
      (tester) async {
    late double fromResolve;
    late double fromWidget;

    await tester.pumpWidget(
      MaterialApp(
        home: IconTheme(
          data: const IconThemeData(size: 28),
          child: Builder(
            builder: (context) {
              fromResolve = NavReadIcon.resolveLogicalSize(context);
              return NavReadIcon(
                size: fromResolve,
                // Capture the same helper the widget uses internally.
              );
            },
          ),
        ),
      ),
    );

    fromWidget = NavReadIcon.resolveLogicalSize(
      tester.element(find.byType(NavReadIcon)),
      size: 28,
    );

    expect(fromResolve, 28);
    expect(fromWidget, fromResolve);
    expect(
      NavReadIcon.resolveLogicalSize(
        tester.element(find.byType(NavReadIcon)),
      ),
      fromResolve,
    );
  });

  testWidgets('explicit size overrides IconTheme for resolveLogicalSize',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IconTheme(
          data: const IconThemeData(size: 28),
          child: Builder(
            builder: (context) {
              expect(NavReadIcon.resolveLogicalSize(context, size: 32), 32);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });
}
