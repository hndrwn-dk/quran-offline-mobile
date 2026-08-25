import 'dart:math';

import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/hijri_date.dart';

int fnv1a32(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

TimeOfDayPeriod? _periodFromKey(String? key) {
  return switch (key) {
    'morning' => TimeOfDayPeriod.morning,
    'evening' => TimeOfDayPeriod.evening,
    _ => null,
  };
}

TimeOfDayPeriod? homeTaglinePeriod(String text, String language) {
  for (final entry in AppLocalizations.homeTaglinePool(language)) {
    if (entry.text == text) return _periodFromKey(entry.period);
  }
  return null;
}

String pickHomeTagline({
  required String language,
  required String installSalt,
  required String hijriYmd,
  TimeOfDayPeriod? period,
}) {
  final pool = AppLocalizations.homeTaglinePool(language);
  final weighted = <String>[];
  for (final item in pool) {
    final flavor = _periodFromKey(item.period);
    if (period == TimeOfDayPeriod.morning &&
        flavor == TimeOfDayPeriod.evening) {
      continue;
    }
    if (period == TimeOfDayPeriod.evening &&
        flavor == TimeOfDayPeriod.morning) {
      continue;
    }
    final copies = (flavor != null && flavor == period) ? 3 : 1;
    for (var i = 0; i < copies; i++) {
      weighted.add(item.text);
    }
  }
  if (weighted.isEmpty) return pool.first.text;
  final periodKey = period?.name ?? 'any';
  final seed = fnv1a32('$installSalt|$hijriYmd|$periodKey');
  return weighted[Random(seed).nextInt(weighted.length)];
}
