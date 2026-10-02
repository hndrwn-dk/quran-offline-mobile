import 'dart:io';

import 'package:path/path.dart' as p;

/// Writes [bytes] to [target] via a unique temp file + rename.
///
/// Avoids leaving a truncated [target] if the process is killed mid-write
/// (unlike [File.writeAsBytes], which truncates the destination first).
Future<void> writeBytesAtomically(File target, List<int> bytes) async {
  final parent = target.parent;
  if (!await parent.exists()) {
    await parent.create(recursive: true);
  }

  final tmp = File(
    p.join(
      parent.path,
      '${p.basename(target.path)}.tmp.$pid.'
      '${DateTime.now().microsecondsSinceEpoch}',
    ),
  );

  try {
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(target.path);
  } catch (_) {
    if (await tmp.exists()) {
      try {
        await tmp.delete();
      } catch (_) {}
    }
    rethrow;
  }
}
