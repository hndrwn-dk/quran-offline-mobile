import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/utils/async_once.dart';
import 'package:quran_offline/core/utils/atomic_file_write.dart';

void main() {
  group('AsyncOnce', () {
    test('concurrent run shares one in-flight action', () async {
      var runs = 0;
      final once = AsyncOnce();
      final gate = Completer<void>();

      Future<void> action() async {
        runs++;
        await gate.future;
      }

      final a = once.run(action);
      final b = once.run(action);
      expect(runs, 1);
      gate.complete();
      await Future.wait([a, b]);
      expect(runs, 1);
    });

    test('failed run clears latch so next call retries', () async {
      var runs = 0;
      final once = AsyncOnce();

      await expectLater(
        once.run(() async {
          runs++;
          throw StateError('boom');
        }),
        throwsStateError,
      );
      expect(runs, 1);

      await once.run(() async {
        runs++;
      });
      expect(runs, 2);
    });
  });

  group('writeBytesAtomically', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('atomic_write');
    });

    tearDown(() {
      if (tmp.existsSync()) {
        tmp.deleteSync(recursive: true);
      }
    });

    test('replaces an existing target file', () async {
      final target = File('${tmp.path}/bundle.sqlite');
      await target.writeAsBytes(Uint8List.fromList([1, 2, 3, 4]), flush: true);

      await writeBytesAtomically(target, Uint8List.fromList([9, 8, 7, 6, 5]));
      expect(await target.readAsBytes(), [9, 8, 7, 6, 5]);

      final leftovers = tmp
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('.tmp.') || f.path.contains('.bak.'));
      expect(leftovers, isEmpty);
    });

    test('keeps existing bytes when the replacement file cannot be created',
        () async {
      final target = File('${tmp.path}/bundle.sqlite');
      await target.writeAsBytes(Uint8List.fromList([1, 2, 3, 4]), flush: true);

      // Parent path exists as a file, so the temp write cannot complete.
      final blockedParent = File('${tmp.path}/blocked');
      await blockedParent.writeAsBytes(Uint8List.fromList([0]), flush: true);
      final nested = File('${blockedParent.path}/bundle.sqlite');

      await expectLater(
        writeBytesAtomically(nested, Uint8List.fromList([9, 8, 7])),
        throwsA(isA<FileSystemException>()),
      );
      expect(await target.readAsBytes(), [1, 2, 3, 4]);
    });

    test('creates parent directories as needed', () async {
      final target = File('${tmp.path}/nested/dir/data.bin');
      await writeBytesAtomically(target, Uint8List.fromList([42]));
      expect(await target.readAsBytes(), [42]);
    });
  });
}
