import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_offline/core/models/reciter.dart';

const _kSelectedReciterKey = 'selectedReciterId';

/// Holds the currently selected reciter, persisted across launches.
class ReciterNotifier extends StateNotifier<Reciter> {
  ReciterNotifier() : super(ReciterCatalog.byId(ReciterCatalog.defaultReciterId)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kSelectedReciterKey);
    if (id != null) {
      state = ReciterCatalog.byId(id);
    }
  }

  Future<void> select(Reciter reciter) async {
    state = reciter;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedReciterKey, reciter.id);
  }
}

final reciterProvider = StateNotifierProvider<ReciterNotifier, Reciter>((ref) {
  return ReciterNotifier();
});
