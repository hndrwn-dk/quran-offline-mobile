import 'package:quran_offline/core/models/dua_entry.dart';

class ScienceEntry {
  final String id;
  final String category;
  final int sort;
  final LocalizedText title;
  final LocalizedText summary;
  final LocalizedText scienceNote;
  final List<DuaAyahRef> ayahRefs;

  const ScienceEntry({
    required this.id,
    required this.category,
    required this.sort,
    required this.title,
    required this.summary,
    required this.scienceNote,
    required this.ayahRefs,
  });

  factory ScienceEntry.fromJson(Map<String, dynamic> json) {
    final refs = (json['ayahRefs'] as List<dynamic>)
        .map((e) => DuaAyahRef.fromJson(e as Map<String, dynamic>))
        .toList();
    return ScienceEntry(
      id: json['id'] as String,
      category: json['category'] as String,
      sort: json['sort'] as int? ?? 0,
      title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>),
      summary: LocalizedText.fromJson(json['summary'] as Map<String, dynamic>),
      scienceNote:
          LocalizedText.fromJson(json['scienceNote'] as Map<String, dynamic>),
      ayahRefs: refs,
    );
  }

  DuaAyahRef get primaryRef => ayahRefs.first;

  String rangeKey() => ayahRefs.map((r) => r.rangeKey()).join('|');
}
