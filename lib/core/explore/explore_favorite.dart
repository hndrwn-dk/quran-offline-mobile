import 'dart:convert';

import 'package:quran_offline/core/models/asma_entry.dart';
import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/science_entry.dart';
import 'package:quran_offline/core/models/theme_entry.dart';

enum ExploreFavoriteKind { dua, science, asma, theme }

class ExploreFavorite {
  const ExploreFavorite({
    required this.kind,
    required this.id,
    required this.markedAtMillis,
  });

  final ExploreFavoriteKind kind;
  final String id;
  final int markedAtMillis;

  String get key => '${kind.name}:$id';

  Map<String, Object> toJson() => {
        'kind': kind.name,
        'id': id,
        'markedAtMillis': markedAtMillis,
      };
}

class ExploreFavoriteView {
  const ExploreFavoriteView({
    required this.favorite,
    required this.title,
  });

  final ExploreFavorite favorite;
  final String title;
}

List<ExploreFavorite> toggleExploreFavorite(
  List<ExploreFavorite> current,
  ExploreFavoriteKind kind,
  String id,
  int markedAtMillis,
) {
  final next = ExploreFavorite(
    kind: kind,
    id: id,
    markedAtMillis: markedAtMillis,
  );
  if (current.any((item) => item.key == next.key)) {
    return current.where((item) => item.key != next.key).toList();
  }
  return [
    next,
    ...current.where((item) => item.key != next.key),
  ];
}

String encodeExploreFavorites(List<ExploreFavorite> favorites) {
  return jsonEncode(favorites.map((item) => item.toJson()).toList());
}

List<ExploreFavorite> decodeExploreFavorites(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return const [];
  }
  if (decoded is! List) return const [];

  final items = <ExploreFavorite>[];
  for (final entry in decoded) {
    if (entry is! Map) continue;
    final kind = _kindFromName(entry['kind']);
    final id = entry['id'];
    final markedAt = entry['markedAtMillis'];
    if (kind == null || id is! String || id.isEmpty || markedAt is! int) {
      continue;
    }
    items.add(
      ExploreFavorite(kind: kind, id: id, markedAtMillis: markedAt),
    );
  }
  items.sort((a, b) => b.markedAtMillis.compareTo(a.markedAtMillis));
  return items;
}

ExploreFavoriteKind? _kindFromName(Object? name) {
  if (name is! String) return null;
  for (final kind in ExploreFavoriteKind.values) {
    if (kind.name == name) return kind;
  }
  return null;
}

List<ExploreFavoriteView> resolveExploreFavorites({
  required List<ExploreFavorite> favorites,
  required String lang,
  required List<DuaEntry> duas,
  required List<ScienceEntry> science,
  required List<AsmaEntry> asma,
  required List<ThemeEntry> themes,
}) {
  final views = <ExploreFavoriteView>[];
  for (final favorite in favorites) {
    final title = _titleFor(favorite, lang, duas, science, asma, themes);
    if (title == null || title.isEmpty) continue;
    views.add(ExploreFavoriteView(favorite: favorite, title: title));
  }
  return views;
}

String? _titleFor(
  ExploreFavorite favorite,
  String lang,
  List<DuaEntry> duas,
  List<ScienceEntry> science,
  List<AsmaEntry> asma,
  List<ThemeEntry> themes,
) {
  switch (favorite.kind) {
    case ExploreFavoriteKind.dua:
      for (final entry in duas) {
        if (entry.id == favorite.id) return entry.title.forLanguage(lang);
      }
      return null;
    case ExploreFavoriteKind.science:
      for (final entry in science) {
        if (entry.id == favorite.id) return entry.title.forLanguage(lang);
      }
      return null;
    case ExploreFavoriteKind.asma:
      for (final entry in asma) {
        if (entry.id == favorite.id) return entry.title.forLanguage(lang);
      }
      return null;
    case ExploreFavoriteKind.theme:
      for (final entry in themes) {
        if (entry.id == favorite.id) return entry.title.forLanguage(lang);
      }
      return null;
  }
}
