import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/science_catalog_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('science catalog provider loads from asset bundle', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final catalog = await container.read(scienceCatalogProvider.future);
    expect(catalog.entries.length, greaterThanOrEqualTo(15));
  });
}
