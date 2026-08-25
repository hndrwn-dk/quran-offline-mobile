import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';

void main() {
  test('getHijriHeadline formats Indonesian date', () {
    const hijri = HijriDate(year: 1448, month: 2, day: 27);
    final text = AppLocalizations.getHijriHeadline(
      language: 'id',
      weekday: DateTime.friday,
      hijri: hijri,
    );
    expect(text, 'Jumat, 27 Safar 1448');
  });

  test('getHijriHeadline appends Ramadan occasion', () {
    const hijri = HijriDate(year: 1447, month: 9, day: 10);
    final text = AppLocalizations.getHijriHeadline(
      language: 'id',
      weekday: DateTime.monday,
      hijri: hijri,
      occasionBadgeKey: 'ramadan',
    );
    expect(
      text,
      'Senin, 10 Ramadan 1447 — ${AppLocalizations.getReflectionBadge('ramadan', 'id')}',
    );
  });

  test('getFridayHint is pure', () {
    expect(AppLocalizations.getFridayHint('en', DateTime.thursday), isNull);
    expect(AppLocalizations.getFridayHint('en', DateTime.friday), isNotNull);
  });

  test('getGregorianWeekdayName uses DateTime weekday numbers', () {
    expect(AppLocalizations.getGregorianWeekdayName(DateTime.monday, 'id'),
        'Senin');
    expect(AppLocalizations.getGregorianWeekdayName(DateTime.sunday, 'en'),
        'Sunday');
  });

  test('getHijriMonthName uses 1-based months', () {
    expect(AppLocalizations.getHijriMonthName(1, 'id'), 'Muharram');
    expect(AppLocalizations.getHijriMonthName(9, 'id'), 'Ramadan');
    expect(AppLocalizations.getHijriMonthName(12, 'id'), 'Dzulhijjah');
  });

  test('getHijriHeadline omits leading zero on day', () {
    const hijri = HijriDate(year: 1448, month: 1, day: 5);
    final text = AppLocalizations.getHijriHeadline(
      language: 'id',
      weekday: DateTime.saturday,
      hijri: hijri,
    );
    expect(text, 'Sabtu, 5 Muharram 1448');
  });

  test('getHijriHeadline appends Hijrah badge with em dash', () {
    const hijri = HijriDate(year: 1448, month: 1, day: 1);
    final text = AppLocalizations.getHijriHeadline(
      language: 'id',
      weekday: DateTime.wednesday,
      hijri: hijri,
      occasionBadgeKey: 'hijrah',
    );
    expect(
      text,
      'Rabu, 1 Muharram 1448 — ${AppLocalizations.getReflectionBadge('hijrah', 'id')}',
    );
  });

  test('getHijriHeadline ignores non-occasion badge keys', () {
    const hijri = HijriDate(year: 1448, month: 2, day: 27);
    final text = AppLocalizations.getHijriHeadline(
      language: 'id',
      weekday: DateTime.friday,
      hijri: hijri,
      occasionBadgeKey: 'friday',
    );
    expect(text, 'Jumat, 27 Safar 1448');
  });

  test('Indonesian after maghrib uses Malam Jumat', () {
    const hijri = HijriDate(year: 1448, month: 2, day: 15);
    final text = AppLocalizations.getHijriHeadline(
      language: 'id',
      weekday: DateTime.friday,
      hijri: hijri,
      clockHour: 20,
    );
    expect(text, 'Malam Jumat, 15 Safar 1448');
  });

  test('English after maghrib uses Eve of Friday', () {
    const hijri = HijriDate(year: 1448, month: 2, day: 15);
    final text = AppLocalizations.getHijriHeadline(
      language: 'en',
      weekday: DateTime.friday,
      hijri: hijri,
      clockHour: 20,
    );
    expect(text, startsWith('Eve of Friday,'));
  });

  test('Japanese after maghrib uses 前夜 not の夜', () {
    const hijri = HijriDate(year: 1448, month: 2, day: 15);
    final text = AppLocalizations.getHijriHeadline(
      language: 'ja',
      weekday: DateTime.friday,
      hijri: hijri,
      clockHour: 20,
    );
    expect(text, startsWith('金曜日の前夜,'));
    expect(text.contains('金曜の夜'), isFalse);
  });

  test('Chinese after maghrib uses 前夜', () {
    const hijri = HijriDate(year: 1448, month: 2, day: 15);
    final text = AppLocalizations.getHijriHeadline(
      language: 'zh',
      weekday: DateTime.friday,
      hijri: hijri,
      clockHour: 20,
    );
    expect(text, startsWith('星期五前夜,'));
  });
}
