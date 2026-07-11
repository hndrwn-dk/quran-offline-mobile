import 'package:quran_offline/core/utils/hijri_date.dart';

/// When to show the Ramadan Tracker promo on Beranda.
class RamadanPromoSchedule {
  const RamadanPromoSchedule({
    required this.daysUntilRamadan,
    required this.inRamadan,
    required this.shouldShowPromo,
  });

  final int daysUntilRamadan;
  final bool inRamadan;
  final bool shouldShowPromo;

  factory RamadanPromoSchedule.fromDateTime(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final hijri = HijriDate.fromGregorian(today);
    final inRamadan = hijri.month == 9;
    final daysUntil = _daysUntilNextRamadanStart(today, inRamadan);
    final shouldShow = inRamadan || (daysUntil >= 0 && daysUntil <= 90);
    return RamadanPromoSchedule(
      daysUntilRamadan: daysUntil,
      inRamadan: inRamadan,
      shouldShowPromo: shouldShow,
    );
  }
}

int _daysUntilNextRamadanStart(DateTime today, bool inRamadan) {
  if (inRamadan) return 0;

  var cursor = today;
  for (var i = 0; i <= 400; i++) {
    final h = HijriDate.fromGregorian(cursor);
    if (h.month == 9 && h.day == 1) {
      return cursor.difference(today).inDays;
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return -1;
}
