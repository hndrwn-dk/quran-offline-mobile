import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';
import 'package:quran_offline/core/utils/home_tagline.dart';

void main() {
  test('same salt and hijri day return the same tagline', () {
    final a = pickHomeTagline(
      language: 'id',
      installSalt: 'abc',
      hijriYmd: '1448-02-27',
      period: TimeOfDayPeriod.morning,
    );
    final b = pickHomeTagline(
      language: 'id',
      installSalt: 'abc',
      hijriYmd: '1448-02-27',
      period: TimeOfDayPeriod.morning,
    );
    expect(a, b);
    expect(a, isNotEmpty);
  });

  test('different salts can yield different taglines', () {
    final seen = <String>{};
    for (var i = 0; i < 40; i++) {
      seen.add(
        pickHomeTagline(
          language: 'id',
          installSalt: 'salt-$i',
          hijriYmd: '1448-02-27',
          period: TimeOfDayPeriod.morning,
        ),
      );
    }
    expect(seen.length, greaterThan(1));
  });

  test('morning selection never uses evening-only taglines', () {
    for (var i = 0; i < 80; i++) {
      final text = pickHomeTagline(
        language: 'id',
        installSalt: 'm-$i',
        hijriYmd: '1448-03-01',
        period: TimeOfDayPeriod.morning,
      );
      expect(homeTaglinePeriod(text, 'id'), isNot(TimeOfDayPeriod.evening));
    }
  });
}
