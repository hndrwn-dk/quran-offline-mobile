import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReflectionTodayCache {
  final String ymd;
  final String id;

  const ReflectionTodayCache({required this.ymd, required this.id});
}

class ReflectionHistoryStore {
  static const saltKey = 'reflection_install_salt';
  static const recentKey = 'reflection_recent_ids';
  static const todayKey = 'reflection_today';

  Future<String> readOrCreateInstallSalt() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(saltKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    await prefs.setString(saltKey, salt);
    return salt;
  }

  Future<ReflectionTodayCache?> readToday() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(todayKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        debugPrint('ReflectionHistoryStore: today cache is not a JSON object');
        return null;
      }
      final json = Map<String, dynamic>.from(decoded);
      final ymd = json['ymd'];
      final id = json['id'];
      if (ymd is! String || id is! String) {
        debugPrint('ReflectionHistoryStore: malformed today cache $raw');
        return null;
      }
      return ReflectionTodayCache(ymd: ymd, id: id);
    } catch (e, st) {
      debugPrint('ReflectionHistoryStore: today parse failed: $e\n$st');
      return null;
    }
  }

  Future<void> writeToday({required String ymd, required String id}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      todayKey,
      jsonEncode({'ymd': ymd, 'id': id}),
    );
  }

  Future<List<String>> readRecentIds({int? cap}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(recentKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final list = decoded.whereType<String>().toList();
      if (cap == null || list.length <= cap) return list;
      return list.sublist(0, cap);
    } catch (e, st) {
      debugPrint('ReflectionHistoryStore: recent parse failed: $e\n$st');
      return const [];
    }
  }

  Future<void> pushRecentId(String id, {int? cap}) async {
    final current = await readRecentIds();
    final next = [id, ...current];
    if (cap != null && next.length > cap) {
      next.removeRange(cap, next.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(recentKey, jsonEncode(next));
  }
}
