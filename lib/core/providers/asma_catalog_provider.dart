import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/models/asma_entry.dart';

class AsmaCatalog {
  final int version;
  final List<AsmaEntry> entries;

  const AsmaCatalog({required this.version, required this.entries});

  List<AsmaEntry> sorted() {
    return List<AsmaEntry>.from(entries)..sort((a, b) => a.sort.compareTo(b.sort));
  }
}

const _asmaCatalogAsset = 'assets/asma/asmaul_husna_catalog.json';

final asmaCatalogProvider = FutureProvider<AsmaCatalog>((ref) async {
  String raw;
  try {
    raw = await rootBundle.loadString(_asmaCatalogAsset);
  } catch (e, st) {
    debugPrint('Asma catalog asset missing ($_asmaCatalogAsset): $e\n$st');
    throw FlutterError(
      'Unable to load asset: $_asmaCatalogAsset. '
      'Stop the app, run flutter pub get, then flutter run again '
      '(hot reload/restart does not bundle new assets).',
    );
  }

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e, st) {
    debugPrint('Asma catalog JSON parse failed: $e\n$st');
    rethrow;
  }
  final items = (json['entries'] as List<dynamic>)
      .map((e) => AsmaEntry.fromJson(e as Map<String, dynamic>))
      .toList();

  final seenIds = <String>{};
  final seenNumbers = <int>{};
  for (final entry in items) {
    if (!seenIds.add(entry.id)) {
      throw StateError('Duplicate asma id: ${entry.id}');
    }
    if (!seenNumbers.add(entry.number)) {
      throw StateError('Duplicate asma number: ${entry.number}');
    }
    if (entry.ayahRefs.isEmpty) {
      throw StateError('Asma ${entry.id} has no ayahRefs');
    }
  }

  if (items.length != 99) {
    throw StateError('Expected 99 asma entries, got ${items.length}');
  }

  return AsmaCatalog(
    version: json['version'] as int? ?? 1,
    entries: items,
  );
});
