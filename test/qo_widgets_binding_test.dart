import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/mushaf/qpc_v2_font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(QpcV2FontLoader.debugReset);

  test('a font change is not claimed unless the loader registered a font', () {
    // A real system font change (or another package's font) must still
    // reach the framework.
    expect(QpcV2FontLoader.consumeOwnFontChange(), isFalse);
  });

  test('each registration claims exactly one font change', () {
    QpcV2FontLoader.debugNoteOwnFontChange();
    QpcV2FontLoader.debugNoteOwnFontChange();
    expect(QpcV2FontLoader.consumeOwnFontChange(), isTrue);
    expect(QpcV2FontLoader.consumeOwnFontChange(), isTrue);
    expect(QpcV2FontLoader.consumeOwnFontChange(), isFalse);
  });

  test('the default (test) binding leaves relayout on register enabled', () {
    expect(QpcV2FontLoader.skipRelayoutOnRegister, isFalse);
  });
}
