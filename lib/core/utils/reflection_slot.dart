enum ReflectionSlot { morning, midday, evening }

ReflectionSlot reflectionSlotForHour(int hour) {
  if (hour >= 5 && hour < 12) return ReflectionSlot.morning;
  if (hour >= 12 && hour < 18) return ReflectionSlot.midday;
  return ReflectionSlot.evening;
}
