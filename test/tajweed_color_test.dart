import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

void main() {
  testWidgets('tajweed rule classes use distinct colors (not plain black)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            const defaultColor = Colors.black;
            final tajweed = TajweedText(
              tajweedHtml: '',
              fontSize: 24,
              defaultColor: defaultColor,
            );

            final madda = tajweed.getTajweedColor('madda_normal', context);
            final wasl = tajweed.getTajweedColor('ham_wasl', context);
            final obligatory = tajweed.getTajweedColor('madda_obligatory', context);
            final idghamGhunnah = tajweed.getTajweedColor('idgham_ghunnah', context);

            expect(madda, isNot(defaultColor));
            expect(wasl, isNot(defaultColor));
            expect(obligatory, isNot(defaultColor));
            expect(idghamGhunnah, isNot(defaultColor));

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
