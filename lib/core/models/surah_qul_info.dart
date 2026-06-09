class SurahQulInfoSection {
  const SurahQulInfoSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  factory SurahQulInfoSection.fromJson(Map<String, dynamic> json) {
    return SurahQulInfoSection(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

class SurahQulInfoEntry {
  const SurahQulInfoEntry({
    required this.short,
    required this.sections,
  });

  final String short;
  final List<SurahQulInfoSection> sections;

  factory SurahQulInfoEntry.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List<dynamic>? ?? const [];
    return SurahQulInfoEntry(
      short: json['short'] as String? ?? '',
      sections: rawSections
          .map((e) => SurahQulInfoSection.fromJson(e as Map<String, dynamic>))
          .where((s) => s.title.isNotEmpty || s.body.isNotEmpty)
          .toList(),
    );
  }
}

/// QUL bundles English and Indonesian only. Follow [translationLanguage];
/// Chinese, Japanese, and other codes fall back to English.
String qulSurahInfoLanguage(String translationLanguage) {
  if (translationLanguage == 'id') return 'id';
  return 'en';
}

class SurahQulInfoBundle {
  const SurahQulInfoBundle({
    required this.source,
    required this.sourceUrl,
    required this.bySurahId,
  });

  final String source;
  final String sourceUrl;
  final Map<int, Map<String, SurahQulInfoEntry>> bySurahId;

  SurahQulInfoEntry? forSurah(int surahId, String language) {
    return bySurahId[surahId]?[language];
  }

  factory SurahQulInfoBundle.fromJson(Map<String, dynamic> json) {
    final surahs = json['surahs'] as Map<String, dynamic>? ?? {};
    final parsed = <int, Map<String, SurahQulInfoEntry>>{};

    for (final entry in surahs.entries) {
      final id = int.tryParse(entry.key);
      if (id == null) continue;
      final langMap = entry.value as Map<String, dynamic>;
      parsed[id] = {
        for (final langEntry in langMap.entries)
          langEntry.key: SurahQulInfoEntry.fromJson(
            langEntry.value as Map<String, dynamic>,
          ),
      };
    }

    return SurahQulInfoBundle(
      source: json['source'] as String? ?? 'QUL',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      bySurahId: parsed,
    );
  }
}
