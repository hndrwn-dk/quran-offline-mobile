import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/ramadan_promo_schedule.dart';

void main() {
  test('shows promo within 90 days before Ramadan start', () {
    final schedule = RamadanPromoSchedule.fromDateTime(DateTime(2026, 2, 1));
    expect(schedule.shouldShowPromo, isTrue);
    expect(schedule.inRamadan, isFalse);
    expect(schedule.daysUntilRamadan, greaterThan(0));
  });

  test('shows promo during Ramadan month', () {
    var found = false;
    for (var day = 1; day <= 28; day++) {
      final schedule = RamadanPromoSchedule.fromDateTime(DateTime(2026, 3, day));
      if (schedule.inRamadan) {
        found = true;
        expect(schedule.shouldShowPromo, isTrue);
        break;
      }
    }
    expect(found, isTrue, reason: 'Expected at least one Ramadan day in March 2026 sample');
  });
}
