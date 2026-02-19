/// Application version info. Keep in sync with pubspec.yaml version.
class AppVersion {
  static const String version = '1.0.0';
  static const int buildNumber = 9;

  /// Full display string, e.g. "1.0.0 (7)"
  static String get display => '$version ($buildNumber)';
}
