import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/whats_new.dart';

/// Release version (pubspec `versionName`, without `+build`), passed at build
/// time with `--dart-define=APP_VERSION=<x.y.z>`. Empty in debug runs,
/// `flutter run` and tests, which keeps the What's new card hidden there;
/// tests override this provider when they need it.
final appVersionProvider = Provider<String>(
  (ref) => const String.fromEnvironment('APP_VERSION'),
);

/// True when Beranda should show the What's new card.
final whatsNewDueProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return whatsNewDue(
    settings.onboarded,
    settings.seenVersion,
    ref.watch(appVersionProvider),
  );
});
