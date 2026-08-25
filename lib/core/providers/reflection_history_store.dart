import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quran_offline/core/utils/reflection_slot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReflectionSlotCache {
  final String ymd;
  final ReflectionSlot slot;
  final String id;
  const ReflectionSlotCache({
    required this.ymd,
    required this.slot,
    required this.id,
  });
}

class ReflectionHistoryStore {
  static const prefsKey = 'reflection_slot_pick';

  String localYmd(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<ReflectionSlotCache?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        debugPrint('ReflectionHistoryStore: cache is not a JSON object');
        return null;
      }
      final json = Map<String, dynamic>.from(decoded);
      final ymd = json['ymd'];
      final id = json['id'];
      final slot = _slotFromName(json['slot']);
      if (ymd is! String || id is! String || slot == null) {
        debugPrint('ReflectionHistoryStore: malformed cache $raw');
        return null;
      }
      return ReflectionSlotCache(ymd: ymd, slot: slot, id: id);
    } catch (e, st) {
      debugPrint('ReflectionHistoryStore: parse failed: $e\n$st');
      return null;
    }
  }

  Future<void> write(ReflectionSlotCache cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      prefsKey,
      jsonEncode({
        'ymd': cache.ymd,
        'slot': cache.slot.name,
        'id': cache.id,
      }),
    );
  }

  ReflectionSlot? _slotFromName(Object? name) {
    return switch (name) {
      'morning' => ReflectionSlot.morning,
      'midday' => ReflectionSlot.midday,
      'evening' => ReflectionSlot.evening,
      _ => null,
    };
  }
}
