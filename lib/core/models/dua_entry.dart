class DuaAyahRef {
  final int surah;
  final int from;
  final int to;

  const DuaAyahRef({
    required this.surah,
    required this.from,
    required this.to,
  });

  factory DuaAyahRef.fromJson(Map<String, dynamic> json) {
    final from = json['from'] as int;
    final to = (json['to'] as int?) ?? from;
    return DuaAyahRef(surah: json['surah'] as int, from: from, to: to);
  }

  String rangeKey() => '$surah:$from:$to';
}

class LocalizedText {
  final String id;
  final String en;
  final String zh;
  final String ja;

  const LocalizedText({
    required this.id,
    required this.en,
    required this.zh,
    required this.ja,
  });

  factory LocalizedText.fromJson(Map<String, dynamic> json) {
    return LocalizedText(
      id: json['id'] as String,
      en: json['en'] as String,
      zh: json['zh'] as String,
      ja: json['ja'] as String,
    );
  }

  String forLanguage(String language) {
    return switch (language) {
      'id' => id,
      'zh' => zh,
      'ja' => ja,
      _ => en,
    };
  }
}

class DuaEntry {
  final String id;
  final String category;
  final String? prophet;
  final String? theme;
  final int sort;
  final LocalizedText title;
  final LocalizedText summary;
  final List<DuaAyahRef> ayahRefs;

  const DuaEntry({
    required this.id,
    required this.category,
    this.prophet,
    this.theme,
    required this.sort,
    required this.title,
    required this.summary,
    required this.ayahRefs,
  });

  factory DuaEntry.fromJson(Map<String, dynamic> json) {
    final refs = (json['ayahRefs'] as List<dynamic>)
        .map((e) => DuaAyahRef.fromJson(e as Map<String, dynamic>))
        .toList();
    return DuaEntry(
      id: json['id'] as String,
      category: json['category'] as String,
      prophet: json['prophet'] as String?,
      theme: json['theme'] as String?,
      sort: json['sort'] as int? ?? 0,
      title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>),
      summary: LocalizedText.fromJson(json['summary'] as Map<String, dynamic>),
      ayahRefs: refs,
    );
  }

  DuaAyahRef get primaryRef => ayahRefs.first;

  String rangeKey() => ayahRefs.map((r) => r.rangeKey()).join('|');
}
