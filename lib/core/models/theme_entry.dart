import 'package:quran_offline/core/models/dua_entry.dart';

class ThemeEntry {
  final String id;
  final String category;
  final int sort;
  final LocalizedText title;
  final LocalizedText summary;
  final LocalizedText reflection;
  final List<DuaAyahRef> ayahRefs;

  const ThemeEntry({
    required this.id,
    required this.category,
    required this.sort,
    required this.title,
    required this.summary,
    required this.reflection,
    required this.ayahRefs,
  });

  factory ThemeEntry.fromJson(Map<String, dynamic> json) {
    final refs = (json['ayahRefs'] as List<dynamic>)
        .map((e) => DuaAyahRef.fromJson(e as Map<String, dynamic>))
        .toList();
    return ThemeEntry(
      id: json['id'] as String,
      category: json['category'] as String,
      sort: json['sort'] as int? ?? 0,
      title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>),
      summary: LocalizedText.fromJson(json['summary'] as Map<String, dynamic>),
      reflection:
          LocalizedText.fromJson(json['reflection'] as Map<String, dynamic>),
      ayahRefs: refs,
    );
  }

  DuaAyahRef get primaryRef => ayahRefs.first;

  int get ayahCount {
    var count = 0;
    for (final ref in ayahRefs) {
      count += ref.to - ref.from + 1;
    }
    return count;
  }
}
