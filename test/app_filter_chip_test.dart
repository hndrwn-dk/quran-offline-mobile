import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/widgets/app_filter_chip.dart';

void main() {
  testWidgets('selected filter chip uses a thin primary border and no check', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFilterChip(
            label: 'Semua',
            selected: true,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check), findsNothing);
    final material = tester.widget<Material>(find.byType(Material).last);
    final scheme = Theme.of(tester.element(find.text('Semua'))).colorScheme;
    expect(material.color, scheme.primaryContainer.withValues(alpha: 0.45));
    final side = (material.shape! as StadiumBorder).side;
    expect(side.color, scheme.primary);
    expect(side.width, 1.5);
    expect(tester.widget<Text>(find.text('Semua')).style?.color, scheme.primary);
  });
}
