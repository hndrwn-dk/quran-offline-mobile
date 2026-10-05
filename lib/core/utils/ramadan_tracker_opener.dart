import 'package:quran_offline/core/constants/app_links.dart';

/// Outcome of opening Ramadan Tracker from Quran Offline.
enum RamadanTrackerOpenResult {
  launchedApp,
  openedStore,
  failed,
}

/// Decides whether to launch the installed sister app or open the store.
///
/// When [installed] is true, prefers package launch (reliable launcher Intent)
/// over custom-scheme deep links, and never falls back to the store.
class RamadanTrackerOpener {
  RamadanTrackerOpener._();

  static Future<RamadanTrackerOpenResult> open({
    required bool installed,
    required Future<bool> Function(String packageId) launchPackage,
    required Future<bool> Function() openStore,
    Future<bool> Function()? launchDeepLink,
  }) async {
    if (installed) {
      if (await launchPackage(AppLinks.ramadanTrackerPackageId)) {
        return RamadanTrackerOpenResult.launchedApp;
      }
      if (launchDeepLink != null && await launchDeepLink()) {
        return RamadanTrackerOpenResult.launchedApp;
      }
      return RamadanTrackerOpenResult.failed;
    }

    if (await openStore()) {
      return RamadanTrackerOpenResult.openedStore;
    }
    return RamadanTrackerOpenResult.failed;
  }
}
