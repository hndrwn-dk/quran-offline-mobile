import 'package:flutter/material.dart';

enum HomeDayPeriod {
  morning,
  afternoon,
  evening,
  night,
}

HomeDayPeriod homeDayPeriodFromTime(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 11) return HomeDayPeriod.morning;
  if (hour >= 11 && hour < 15) return HomeDayPeriod.afternoon;
  if (hour >= 15 && hour < 18) return HomeDayPeriod.evening;
  return HomeDayPeriod.night;
}

IconData homeDayPeriodIcon(HomeDayPeriod period) {
  return switch (period) {
    HomeDayPeriod.morning => Icons.wb_twilight_rounded,
    HomeDayPeriod.afternoon => Icons.wb_sunny_rounded,
    HomeDayPeriod.evening => Icons.wb_cloudy_rounded,
    HomeDayPeriod.night => Icons.nights_stay_rounded,
  };
}

Color homeDayPeriodIconColor(HomeDayPeriod period, ColorScheme colorScheme) {
  return switch (period) {
    HomeDayPeriod.morning => const Color(0xFFE8A317),
    HomeDayPeriod.afternoon => colorScheme.primary,
    HomeDayPeriod.evening => const Color(0xFFE07A2F),
    HomeDayPeriod.night => colorScheme.onSurfaceVariant,
  };
}
