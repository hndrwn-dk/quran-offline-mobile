import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/reflection_slot.dart';

void main() {
  test('reflectionSlotForHour maps morning midday evening', () {
    expect(reflectionSlotForHour(5), ReflectionSlot.morning);
    expect(reflectionSlotForHour(11), ReflectionSlot.morning);
    expect(reflectionSlotForHour(12), ReflectionSlot.midday);
    expect(reflectionSlotForHour(17), ReflectionSlot.midday);
    expect(reflectionSlotForHour(18), ReflectionSlot.evening);
    expect(reflectionSlotForHour(23), ReflectionSlot.evening);
    expect(reflectionSlotForHour(3), ReflectionSlot.evening);
  });
}
