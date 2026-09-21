import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/system_bottom_inset.dart';

void main() {
  test('prefers the larger of viewPadding.bottom and padding.bottom', () {
    expect(
      systemBottomInset(
        const MediaQueryData(
          padding: EdgeInsets.only(bottom: 24),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
      ),
      48,
    );
    expect(
      systemBottomInset(
        const MediaQueryData(
          padding: EdgeInsets.only(bottom: 40),
          viewPadding: EdgeInsets.only(bottom: 16),
        ),
      ),
      40,
    );
  });

  test('returns 0 when neither inset is present', () {
    expect(systemBottomInset(const MediaQueryData()), 0);
  });

  test('imeVisible ignores system-nav-sized insets', () {
    expect(imeVisible(const MediaQueryData()), isFalse);
    expect(
      imeVisible(
        const MediaQueryData(
          viewInsets: EdgeInsets.only(bottom: 48),
          viewPadding: EdgeInsets.only(bottom: 48),
        ),
      ),
      isFalse,
    );
    expect(
      imeVisible(
        const MediaQueryData(
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
      ),
      isTrue,
    );
  });
}
