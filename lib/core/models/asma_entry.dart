import 'package:quran_offline/core/models/dua_entry.dart';

class AsmaEntry {
  final String id;
  final int number;
  final int sort;
  final String arabic;
  final String transliteration;
  final LocalizedText title;
  final LocalizedText summary;
  final LocalizedText reflection;
  final List<DuaAyahRef> ayahRefs;

  const AsmaEntry({
    required this.id,
    required this.number,
    required this.sort,
    required this.arabic,
    required this.transliteration,
    required this.title,
    required this.summary,
    required this.reflection,
    required this.ayahRefs,
  });

  factory AsmaEntry.fromJson(Map<String, dynamic> json) {
    final refs = (json['ayahRefs'] as List<dynamic>)
        .map((e) => DuaAyahRef.fromJson(e as Map<String, dynamic>))
        .toList();
    return AsmaEntry(
      id: json['id'] as String,
      number: json['number'] as int,
      sort: json['sort'] as int? ?? json['number'] as int,
      arabic: json['arabic'] as String,
      transliteration: json['transliteration'] as String,
      title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>),
      summary: LocalizedText.fromJson(json['summary'] as Map<String, dynamic>),
      reflection:
          LocalizedText.fromJson(json['reflection'] as Map<String, dynamic>),
      ayahRefs: refs,
    );
  }

  DuaAyahRef get primaryRef => ayahRefs.first;

  String rangeKey() => ayahRefs.map((r) => r.rangeKey()).join('|');
}
