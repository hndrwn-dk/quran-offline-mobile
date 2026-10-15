/// Application version info. Keep in sync with pubspec.yaml version.
class AppVersion {
  static const String version = '1.0.20';
  static const int buildNumber = 66;

  /// Full display string, e.g. "1.0.1 (18)"
  static String get display => '$version ($buildNumber)';
}
