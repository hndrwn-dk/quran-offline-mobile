import 'package:quran_offline/core/models/dua_entry.dart';

class QuranDuaNeed {
  final String id;
  final String en;

  const QuranDuaNeed({
    required this.id,
    required this.en,
  });

  factory QuranDuaNeed.fromJson(Map<String, dynamic> json) {
    return QuranDuaNeed(
      id: json['id'] as String,
      en: json['en'] as String,
    );
  }
}

class QuranDuaAyatEntry {
  final String id;
  final DuaAyahRef ref;
  final String? category;
  final List<String> tags;
  final QuranDuaNeed need;
  final bool recommendedToRecite;
  final bool inDuaCatalog;
  final List<String> duaCatalogIds;
  final String source;

  const QuranDuaAyatEntry({
    required this.id,
    required this.ref,
    this.category,
    required this.tags,
    required this.need,
    required this.recommendedToRecite,
    required this.inDuaCatalog,
    required this.duaCatalogIds,
    required this.source,
  });

  factory QuranDuaAyatEntry.fromJson(Map<String, dynamic> json) {
    return QuranDuaAyatEntry(
      id: json['id'] as String,
      ref: DuaAyahRef.fromJson(json),
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      need: QuranDuaNeed.fromJson(json['need'] as Map<String, dynamic>),
      recommendedToRecite: json['recommendedToRecite'] as bool,
      inDuaCatalog: json['inDuaCatalog'] as bool? ?? false,
      duaCatalogIds: (json['duaCatalogIds'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      source: json['source'] as String? ?? 'extractor',
    );
  }

  String rangeKey() => ref.rangeKey();
}
