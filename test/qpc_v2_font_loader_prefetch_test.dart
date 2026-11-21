import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(QpcV2FontLoader.debugReset);

  test('prefetch only queues fonts (no load mid page turn)', () {
    QpcV2FontLoader.prefetchPages([7, 6, 7, 0, 605, 8]);
    expect(QpcV2FontLoader.debugPrefetchQueue, [7, 6, 8]);
    expect(QpcV2FontLoader.isLoaded(7), isFalse);
  });
}
