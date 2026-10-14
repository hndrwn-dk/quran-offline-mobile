import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/explore/explore_favorite.dart';
import 'package:shared_preferences/shared_preferences.dart';

final exploreFavoritesProvider =
    StateNotifierProvider<ExploreFavoritesNotifier, List<ExploreFavorite>>(
  (ref) => ExploreFavoritesNotifier(),
);

class ExploreFavoritesNotifier extends StateNotifier<List<ExploreFavorite>> {
  ExploreFavoritesNotifier() : super(const []) {
    _load();
  }

  static const _prefsKey = 'explore_favorites_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = decodeExploreFavorites(prefs.getString(_prefsKey));
  }

  Future<void> toggle(ExploreFavoriteKind kind, String id) async {
    final next = toggleExploreFavorite(
      state,
      kind,
      id,
      DateTime.now().millisecondsSinceEpoch,
    );
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, encodeExploreFavorites(next));
  }

  bool contains(ExploreFavoriteKind kind, String id) {
    return state.any((item) => item.kind == kind && item.id == id);
  }
}
