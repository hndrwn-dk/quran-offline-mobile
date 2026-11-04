/// "What's new" card rules.
///
/// Versioning: a feature/enhancement release bumps the minor version
/// (1.2.x -> 1.3.0); a fix-only release bumps the patch (1.3.0 -> 1.3.1).
/// The card compares only the feature version (major.minor), so a fix
/// release never shows it and skipping 1.3.0/1.3.1 still shows the 1.3
/// features once.
library;

/// First two parts of [v]: '1.3.1' -> '1.3', '2.0.0' -> '2.0', '' -> ''.
String featureVersion(String v) {
  final parts = v.trim().split('+').first.split('.');
  if (parts.length < 2) return parts.first;
  return '${parts[0]}.${parts[1]}';
}

/// Whether the What's new card should show on Beranda.
///
/// [onboarded] false (first-run setup not finished) and an empty [version]
/// (debug builds, `flutter run`, tests: no `APP_VERSION` define) never show
/// it.
bool whatsNewDue(bool onboarded, String seen, String version) =>
    onboarded &&
    version.isNotEmpty &&
    featureVersion(seen) != featureVersion(version);
