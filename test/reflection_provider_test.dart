import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reflection pick provider loads catalogs and returns a pick', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final pick = await container.read(reflectionPickProvider.future);
    expect(pick.entry.id, isNotEmpty);
    expect(pick.entry.title.id, isNotEmpty);
    expect(pick.entry.title.en, isNotEmpty);
    expect(pick.entry.title.zh, isNotEmpty);
    expect(pick.entry.title.ja, isNotEmpty);
    expect(pick.entry.ayahRefs, isNotEmpty);
  });
}
