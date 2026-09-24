import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FTS5 is available on the sqlite3_flutter_libs stack', (tester) async {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();

    late final Database db;
    try {
      db = sqlite3.openInMemory();
    } catch (e) {
      fail(
        'Could not open an in-memory database through sqlite3_flutter_libs: $e',
      );
    }

    try {
      final version = db.select('SELECT sqlite_version() AS v').first['v'];
      // ignore: avoid_print
      print('sqlite_version=$version');

      final enabled = db.select(
        "SELECT sqlite_compileoption_used('ENABLE_FTS5') AS enabled",
      ).first['enabled'];
      // ignore: avoid_print
      print("sqlite_compileoption_used('ENABLE_FTS5')=$enabled");

      try {
        db.execute('CREATE VIRTUAL TABLE fts_probe USING fts5(x);');
      } catch (e) {
        fail('FTS5 unavailable: CREATE VIRTUAL TABLE fts5 failed: $e');
      }

      db.execute("INSERT INTO fts_probe(x) VALUES ('rezeki');");
      final count = db.select(
        "SELECT count(*) AS n FROM fts_probe WHERE fts_probe MATCH 'rezeki'",
      ).first['n'] as int;
      // ignore: avoid_print
      print('fts_probe MATCH rezeki count=$count');

      expect(
        enabled,
        isNot(0),
        reason: "sqlite_compileoption_used('ENABLE_FTS5') is 0",
      );
      expect(count, 1, reason: 'FTS5 MATCH did not return the inserted row');
    } finally {
      db.dispose();
    }
  });
}
