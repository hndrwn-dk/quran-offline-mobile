import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/quran_dua_ayat_catalog_provider.dart';
import 'package:quran_offline/features/dua/life_situation.dart';

const _catalogAsset = 'assets/ai/quran_dua_ayat_catalog.json';

final _arabicScript = RegExp(r'[\u0600-\u06FF]');

const _fixtureCatalog = '''
{
  "version": 1,
  "generatedAtUtc": "2026-01-01T00:00:00Z",
  "quranManifestVersion": "test",
  "note": "References only.",
  "entries": [
    {
      "id": "qd_003_191_194",
      "surah": 3,
      "from": 191,
      "to": 194,
      "category": "forgiveness",
      "tags": ["tag_a"],
      "need": { "id": "fixture_a", "en": "fixture a" },
      "recommendedToRecite": true,
      "inDuaCatalog": false,
      "duaCatalogIds": [],
      "source": "extractor"
    },
    {
      "id": "qd_001_001_001",
      "surah": 1,
      "from": 1,
      "to": 1,
      "category": null,
      "tags": ["tag_b"],
      "need": { "id": "fixture_b", "en": "fixture b" },
      "recommendedToRecite": false,
      "inDuaCatalog": false,
      "duaCatalogIds": [],
      "source": "extractor"
    },
    {
      "id": "qd_112_001_004",
      "surah": 112,
      "from": 1,
      "to": 4,
      "category": "hope",
      "tags": ["tag_c"],
      "need": { "id": "fixture_c", "en": "fixture c" },
      "recommendedToRecite": true,
      "inDuaCatalog": true,
      "duaCatalogIds": ["dua_fixture"],
      "source": "extractor"
    }
  ]
}
''';

Map<int, int>? _maxAyahBySurah() {
  final first = File('assets/quran/s001.json');
  if (!first.existsSync()) return null;
  final maxAyah = <int, int>{};
  for (var s = 1; s <= 114; s++) {
    final path = 'assets/quran/s${s.toString().padLeft(3, '0')}.json';
    final file = File(path);
    if (!file.existsSync()) continue;
    final list = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    var max = 0;
    for (final item in list) {
      final a = (item as Map<String, dynamic>)['a'] as int;
      if (a > max) max = a;
    }
    maxAyah[s] = max;
  }
  return maxAyah;
}

void _assertNoArabic(String raw) {
  expect(_arabicScript.hasMatch(raw), isFalse, reason: 'catalog contains Arabic');
}

void _assertEntryMaps(
  List<Map<String, dynamic>> entries, {
  required Map<int, int>? maxAyah,
}) {
  final ids = <String>{};
  for (final entry in entries) {
    final id = entry['id'] as String;
    expect(ids.add(id), isTrue, reason: 'duplicate id $id');

    final surah = entry['surah'] as int;
    final from = entry['from'] as int;
    final to = (entry['to'] as int?) ?? from;
    expect(surah, inInclusiveRange(1, 114));
    expect(from, greaterThan(0));
    expect(to, greaterThanOrEqualTo(from));
    if (maxAyah != null) {
      expect(maxAyah.containsKey(surah), isTrue);
      expect(from, lessThanOrEqualTo(maxAyah[surah]!));
      expect(to, lessThanOrEqualTo(maxAyah[surah]!));
    }

    final category = entry['category'] as String?;
    expect(
      category == null || lifeSituationCategoryOrder.contains(category),
      isTrue,
      reason: 'category $category not in lifeSituationCategoryOrder',
    );
  }
}

void main() {
  test('fixture catalog has unique ids, bounds, null category, and no Arabic', () {
    expect(_arabicScript.hasMatch(_fixtureCatalog), isFalse);
    final json = jsonDecode(_fixtureCatalog) as Map<String, dynamic>;
    final catalog = QuranDuaAyatCatalog.fromJson(json);
    expect(catalog.entries, hasLength(3));
    expect(catalog.entries.map((e) => e.id).toSet(), hasLength(3));

    final ranged = catalog.entries.firstWhere((e) => e.id == 'qd_003_191_194');
    expect(ranged.ref.surah, 3);
    expect(ranged.ref.from, 191);
    expect(ranged.ref.to, 194);
    expect(ranged.need.id, 'fixture_a');
    expect(ranged.need.en, 'fixture a');

    final nullable = catalog.entries.firstWhere((e) => e.id == 'qd_001_001_001');
    expect(nullable.category, isNull);

    final rawEntries = (json['entries'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    _assertEntryMaps(rawEntries, maxAyah: _maxAyahBySurah());
    _assertNoArabic(_fixtureCatalog);
  });

  test('bundled catalog has unique ids, valid ranges, categories, and no Arabic', () {
    final catalogFile = File(_catalogAsset);
    if (!catalogFile.existsSync()) {
      markTestSkipped('$_catalogAsset missing');
      return;
    }

    final raw = catalogFile.readAsStringSync();
    _assertNoArabic(raw);

    final catalogJson = jsonDecode(raw) as Map<String, dynamic>;
    final catalog = QuranDuaAyatCatalog.fromJson(catalogJson);
    final entries = (catalogJson['entries'] as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
    expect(catalog.entries, hasLength(entries.length));
    _assertEntryMaps(entries, maxAyah: _maxAyahBySurah());
  });
}
