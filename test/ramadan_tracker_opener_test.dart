import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/constants/app_links.dart';
import 'package:quran_offline/core/utils/ramadan_tracker_opener.dart';

void main() {
  group('RamadanTrackerOpener.open', () {
    test('when installed launches package and does not open store', () async {
      String? launchedPackage;
      var storeOpened = false;

      final result = await RamadanTrackerOpener.open(
        installed: true,
        launchPackage: (packageId) async {
          launchedPackage = packageId;
          return true;
        },
        openStore: () async {
          storeOpened = true;
          return true;
        },
      );

      expect(result, RamadanTrackerOpenResult.launchedApp);
      expect(launchedPackage, AppLinks.ramadanTrackerPackageId);
      expect(storeOpened, isFalse);
    });

    test('when not installed opens store and does not launch package', () async {
      var packageLaunched = false;
      var storeOpened = false;

      final result = await RamadanTrackerOpener.open(
        installed: false,
        launchPackage: (_) async {
          packageLaunched = true;
          return true;
        },
        openStore: () async {
          storeOpened = true;
          return true;
        },
      );

      expect(result, RamadanTrackerOpenResult.openedStore);
      expect(packageLaunched, isFalse);
      expect(storeOpened, isTrue);
    });

    test('when installed and package launch fails tries deep link before store',
        () async {
      var deepLinkTried = false;
      var storeOpened = false;

      final result = await RamadanTrackerOpener.open(
        installed: true,
        launchPackage: (_) async => false,
        launchDeepLink: () async {
          deepLinkTried = true;
          return true;
        },
        openStore: () async {
          storeOpened = true;
          return true;
        },
      );

      expect(result, RamadanTrackerOpenResult.launchedApp);
      expect(deepLinkTried, isTrue);
      expect(storeOpened, isFalse);
    });

    test('when installed and both app launches fail does not open store',
        () async {
      var storeOpened = false;

      final result = await RamadanTrackerOpener.open(
        installed: true,
        launchPackage: (_) async => false,
        launchDeepLink: () async => false,
        openStore: () async {
          storeOpened = true;
          return true;
        },
      );

      expect(result, RamadanTrackerOpenResult.failed);
      expect(storeOpened, isFalse);
    });
  });
}
