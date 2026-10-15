import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quran_offline/core/support/ayah_dwell.dart';
import 'package:quran_offline/core/support/khatam_coverage.dart';
import 'package:quran_offline/core/support/reading_milestone.dart';
import 'package:quran_offline/core/support/support_prompt_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QueuedMilestone {
  const _QueuedMilestone(this.milestone, this.cycle);

  final ReadingMilestone milestone;
  final int cycle;

  String get storageId => '$cycle:${milestone.id}';
}

/// Persists the khatam bitset and the Beranda celebration card.
class ReadingCoverageController extends ChangeNotifier {
  ReadingCoverageController({
    SharedPreferences? prefs,
    DateTime Function()? clock,
    this.writeDelay = const Duration(milliseconds: 500),
  }) : _clock = clock ?? DateTime.now {
    _policy = SupportPromptPolicy(clock: _clock);
    _ready = _load(prefs);
  }

  static const bitsKey = 'support_coverage_bits_v1';
  static const cycleKey = 'support_coverage_cycle_v1';
  static const shownKey = 'support_milestones_shown_v1';
  static const cardKey = 'support_active_card_v1';
  static const pendingKey = 'support_pending_milestones_v1';
  static const lastAskKey = 'support_last_ask_at_v1';
  static const lastPurchaseKey = 'support_last_purchase_at_v1';

  final DateTime Function() _clock;
  final Duration writeDelay;

  late final SupportPromptPolicy _policy;
  late final Future<void> _ready;

  SharedPreferences? _prefs;
  KhatamCoverage _coverage = KhatamCoverage();
  Set<String> _shown = {};
  List<_QueuedMilestone> _pending = [];
  ActiveReadingCard? _card;
  DateTime? _lastAskAt;
  DateTime? _lastPurchaseAt;
  Timer? _bitsTimer;
  var _bitsDirty = false;

  ActiveReadingCard? get card => _card;

  Future<void> markDwelled(AyahRef ayah) async {
    await _ready;
    final update = _coverage.mark(ayah.surah, ayah.ayah);
    if (!update.counted) return;
    final before = _card?.storageId;
    final milestone = milestoneFor(update);
    if (milestone != null) {
      _enqueue(milestone, update.cycle);
      _showNext();
      await _persistCard();
    }
    _scheduleBits();
    if (update.khatam) await _flushBits();
    if (_card?.storageId != before || update.khatam) notifyListeners();
  }

  Future<void> onHomeVisible() async {
    await _ready;
    final before = _card?.storageId;
    _showNext();
    if (_card?.storageId == before) return;
    await _persistCard();
    notifyListeners();
  }

  Future<void> dismissCard() async {
    await _ready;
    if (_card == null) return;
    final step = _policy.dismiss(
      PromptStep(card: _card, shown: _shown, lastAskAt: _lastAskAt),
    );
    _card = null;
    _shown = step.shown;
    _lastAskAt = step.lastAskAt;
    await _persistCard();
    notifyListeners();
  }

  Future<void> recordPurchase() async {
    await _ready;
    _lastPurchaseAt = _clock();
    await _prefs?.setInt(lastPurchaseKey, _lastPurchaseAt!.millisecondsSinceEpoch);
  }

  Future<void> _load(SharedPreferences? injected) async {
    final prefs = injected ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    final raw = prefs.getString(bitsKey);
    final cycle = prefs.getInt(cycleKey) ?? 1;
    if (raw != null) {
      try {
        _coverage = KhatamCoverage.fromBytes(base64Decode(raw), cycle: cycle);
      } catch (_) {
        _coverage = KhatamCoverage(cycle: cycle);
      }
    } else {
      _coverage = KhatamCoverage(cycle: cycle);
    }
    _shown = (prefs.getStringList(shownKey) ?? const []).toSet();
    _card = _decodeCard(prefs.getString(cardKey));
    _pending = _decodePending(prefs.getString(pendingKey));
    final askMs = prefs.getInt(lastAskKey);
    final purchaseMs = prefs.getInt(lastPurchaseKey);
    _lastAskAt = askMs == null ? null : DateTime.fromMillisecondsSinceEpoch(askMs);
    _lastPurchaseAt =
        purchaseMs == null ? null : DateTime.fromMillisecondsSinceEpoch(purchaseMs);
    _showNext();
  }

  void _enqueue(ReadingMilestone milestone, int cycle) {
    final queued = _QueuedMilestone(milestone, cycle);
    if (_shown.contains(queued.storageId)) return;
    if (_card?.storageId == queued.storageId) return;
    if (_pending.any((item) => item.storageId == queued.storageId)) return;
    _pending.add(queued);
  }

  void _showNext() {
    while (true) {
      final pending = _pending.isEmpty ? null : _pending.first;
      final beforeId = _card?.storageId;
      final step = _policy.present(
        current: _card,
        shown: _shown,
        cycle: _coverage.cycle,
        milestone: pending?.milestone,
        milestoneCycle: pending?.cycle,
        lastAskAt: _lastAskAt,
        lastPurchaseAt: _lastPurchaseAt,
      );
      _shown = step.shown;
      _card = step.card;
      if (pending == null) return;
      final showingThis = step.card?.storageId == pending.storageId && beforeId != pending.storageId;
      final blocked = step.card != null && step.card!.storageId != pending.storageId;
      if (blocked) return;
      _pending.removeAt(0);
      if (showingThis) return;
    }
  }

  void _scheduleBits() {
    _bitsDirty = true;
    _bitsTimer?.cancel();
    _bitsTimer = Timer(writeDelay, () {
      _flushBits();
    });
  }

  Future<void> _flushBits() async {
    _bitsTimer?.cancel();
    if (!_bitsDirty) return;
    _bitsDirty = false;
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(bitsKey, base64Encode(_coverage.toBytes()));
    await prefs.setInt(cycleKey, _coverage.cycle);
  }

  Future<void> _persistCard() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setStringList(shownKey, _shown.toList());
    await prefs.setString(pendingKey, jsonEncode(_pending.map(_pendingJson).toList()));
    final encoded = _encodeCard(_card);
    if (encoded == null) {
      await prefs.remove(cardKey);
    } else {
      await prefs.setString(cardKey, encoded);
    }
    if (_lastAskAt == null) {
      await prefs.remove(lastAskKey);
    } else {
      await prefs.setInt(lastAskKey, _lastAskAt!.millisecondsSinceEpoch);
    }
    await prefs.setInt(cycleKey, _coverage.cycle);
  }

  Map<String, Object?> _pendingJson(_QueuedMilestone item) {
    return {
      'cycle': item.cycle,
      'kind': item.milestone.kind.name,
      'completed': item.milestone.completedJuz,
      'juz': item.milestone.juzNumber,
    };
  }

  String? _encodeCard(ActiveReadingCard? card) {
    if (card == null) return null;
    return jsonEncode({
      'cycle': card.cycle,
      'kind': card.milestone.kind.name,
      'completed': card.milestone.completedJuz,
      'juz': card.milestone.juzNumber,
      'shownAt': card.shownAt.millisecondsSinceEpoch,
      'ask': card.askVisible,
    });
  }

  ActiveReadingCard? _decodeCard(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ActiveReadingCard(
        milestone: ReadingMilestone(
          kind: ReadingMilestoneKind.values.byName(json['kind'] as String),
          completedJuz: json['completed'] as int,
          juzNumber: json['juz'] as int?,
        ),
        cycle: json['cycle'] as int,
        shownAt: DateTime.fromMillisecondsSinceEpoch(json['shownAt'] as int),
        askVisible: json['ask'] as bool,
      );
    } catch (_) {
      return null;
    }
  }

  List<_QueuedMilestone> _decodePending(String? raw) {
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>)
            _QueuedMilestone(
              ReadingMilestone(
                kind: ReadingMilestoneKind.values.byName(item['kind'] as String),
                completedJuz: item['completed'] as int,
                juzNumber: item['juz'] as int?,
              ),
              item['cycle'] as int,
            ),
      ];
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _bitsTimer?.cancel();
    if (_bitsDirty) {
      _flushBits();
    }
    super.dispose();
  }
}
