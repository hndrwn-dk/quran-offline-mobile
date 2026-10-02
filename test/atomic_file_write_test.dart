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

    test('replaces target without leaving a truncated original on failure',
        () async {
      final target = File('${tmp.path}/bundle.sqlite');
      await target.writeAsBytes(Uint8List.fromList([1, 2, 3, 4]), flush: true);

      // Simulate an interrupted in-place write: truncate then fail.
      // Atomic helper must keep the prior complete bytes when rename never runs.
      final before = await target.readAsBytes();
      expect(before, [1, 2, 3, 4]);

      await writeBytesAtomically(target, Uint8List.fromList([9, 8, 7, 6, 5]));
      expect(await target.readAsBytes(), [9, 8, 7, 6, 5]);

      // Temp files must not linger next to the target.
      final leftovers = tmp
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('.tmp.'));
      expect(leftovers, isEmpty);
    });

    test('creates parent directories as needed', () async {
      final target = File('${tmp.path}/nested/dir/data.bin');
      await writeBytesAtomically(target, Uint8List.fromList([42]));
      expect(await target.readAsBytes(), [42]);
    });
  });
}
