import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:quran_offline/core/ai_search/ai_search_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

/// Turns a space-separated FTS query into any-term OR, keeping `(syn OR syn)` groups intact.
String ftsAnyTermQuery(String query) {
  final terms = <String>[];
  final buf = StringBuffer();
  var depth = 0;
  for (var i = 0; i < query.length; i++) {
    final c = query[i];
    if (c == '(') {
      depth++;
      buf.write(c);
    } else if (c == ')') {
      if (depth > 0) depth--;
      buf.write(c);
    } else if (c == ' ' && depth == 0) {
      final token = buf.toString().trim();
      buf.clear();
      if (token.isEmpty) continue;
      if (token.toUpperCase() == 'OR') continue;
      terms.add(token);
    } else {
      buf.write(c);
    }
  }
  final last = buf.toString().trim();
  if (last.isNotEmpty && last.toUpperCase() != 'OR') {
    terms.add(last);
  }
  if (terms.isEmpty) return query.trim();
  if (terms.length == 1) return terms.first;
  return terms.join(' OR ');
}

class IndexHit {
  final String docId;
  final String type;
  final String lang;
  final String refKey;
  final int? surah;
  final int? ayahFrom;
  final int? ayahTo;
  final double score;

  const IndexHit({
    required this.docId,
    required this.type,
    required this.lang,
    required this.refKey,
    this.surah,
    this.ayahFrom,
    this.ayahTo,
    required this.score,
  });
}

/// Offline FTS5 index. Returns refs and scores only; never display text.
class SearchIndexRepository {
  SearchIndexRepository();

  Database? _db;

  Future<void> openPath(String path, {bool readOnly = true}) async {
    close();
    _db = sqlite3.open(
      path,
      mode: readOnly ? OpenMode.readOnly : OpenMode.readWrite,
    );
  }

  Future<void> ensureReady() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'ai_search'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final localFile = File(p.join(dir.path, 'search_index.sqlite'));
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(kSearchIndexBuiltAtPrefKey);

    var needCopy = !await localFile.exists();
    if (!needCopy) {
      await openPath(localFile.path);
      final builtAt = _meta('built_at_utc');
      if (stored != builtAt) needCopy = true;
    }

    if (needCopy) {
      close();
      final bytes = await rootBundle.load(kSearchIndexAssetPath);
      await localFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      await openPath(localFile.path);
      final builtAt = _meta('built_at_utc') ?? '';
      await prefs.setString(kSearchIndexBuiltAtPrefKey, builtAt);
    } else if (_db == null) {
      await openPath(localFile.path);
    }
  }

  String? _meta(String key) {
    final db = _db;
    if (db == null) return null;
    final rows = db.select('SELECT value FROM meta WHERE key = ?', [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<List<IndexHit>> keywordSearch(
    String query, {
    Set<String>? types,
    String lang = 'id',
    int limit = 100,
  }) async {
    final db = _db;
    if (db == null || query.trim().isEmpty) return [];

    final match = ftsAnyTermQuery(query.trim());
    final rows = db.select(
      '''
      SELECT
        docs.doc_id AS doc_id,
        docs.type AS type,
        docs.lang AS lang,
        docs.ref_key AS ref_key,
        docs.surah AS surah,
        docs.ayah_from AS ayah_from,
        docs.ayah_to AS ayah_to,
        bm25(docs_fts) AS rank
      FROM docs_fts
      JOIN docs ON docs.rowid = docs_fts.rowid
      WHERE docs_fts MATCH ?
        AND docs.lang = ?
      ORDER BY rank
      LIMIT 100
      ''',
      [match, lang],
    );

    if (rows.isEmpty) return [];

    final raw = <double>[];
    for (final row in rows) {
      final rank = (row['rank'] as num).toDouble();
      raw.add(-rank);
    }
    var minV = raw.first;
    var maxV = raw.first;
    for (final v in raw) {
      minV = min(minV, v);
      maxV = max(maxV, v);
    }
    final span = maxV - minV;

    final hits = <IndexHit>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final type = row['type'] as String;
      if (types != null && !types.contains(type)) continue;
      final score = span == 0 ? 1.0 : (raw[i] - minV) / span;
      hits.add(
        IndexHit(
          docId: row['doc_id'] as String,
          type: type,
          lang: row['lang'] as String,
          refKey: row['ref_key'] as String,
          surah: row['surah'] as int?,
          ayahFrom: row['ayah_from'] as int?,
          ayahTo: row['ayah_to'] as int?,
          score: score,
        ),
      );
    }
    if (hits.length > limit) {
      return hits.sublist(0, limit);
    }
    return hits;
  }

  Future<List<String>> relatedDocIds(int surah, int ayah) async {
    final db = _db;
    if (db == null) return [];
    final rows = db.select(
      'SELECT DISTINCT doc_id FROM doc_refs WHERE surah = ? AND ayah = ?',
      [surah, ayah],
    );
    return [for (final row in rows) row['doc_id'] as String];
  }

  void close() {
    _db?.dispose();
    _db = null;
  }
}
