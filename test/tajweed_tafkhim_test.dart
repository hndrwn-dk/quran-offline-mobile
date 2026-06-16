import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/tajweed/tajweed_html.dart';
import 'package:quran_offline/core/tajweed/tajweed_parser.dart';
import 'package:quran_offline/core/widgets/tajweed_text.dart';

void main() {
  test('U+06E1 tafkhim marker becomes tafkhim tag', () {
    const input = 'أَص\u06e1حَ';
    final prepared = TajweedHtml.prepareForParsing(input);
    expect(prepared, contains('class=tafkhim'));
    expect(prepared, isNot(contains('\u06e1')));
  });

  testWidgets('tafkhim span uses dark blue, not default black', (tester) async {
  const html = 'أَ<tajweed class=tafkhim>ص</tajweed>حَ';

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Builder(
          builder: (context) {
            final spans = TajweedParser.parseToSpans(
              context: context,
              tajweedHtml: html,
              baseStyle: TajweedText.arabicDisplayStyle(
                fontSize: 24,
                color: Colors.black,
              ),
              defaultColor: Colors.black,
            );
            final colored = spans.where(
              (s) => s.style?.color != null && s.style!.color != Colors.black,
            );
            expect(colored, isNotEmpty);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('madda and ham wasl use distinct quran.com palette colors', (tester) async {
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
            final tafkhim = tajweed.getTajweedColor('tafkhim', context);
            final qalqalah = tajweed.getTajweedColor('qalqalah', context);

            expect(madda, isNot(defaultColor));
            expect(wasl, isNot(defaultColor));
            expect(tafkhim, isNot(defaultColor));
            expect(qalqalah, isNot(defaultColor));
            expect(madda, isNot(tafkhim));

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
