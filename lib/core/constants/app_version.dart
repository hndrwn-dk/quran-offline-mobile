/// Application version info. Keep in sync with pubspec.yaml version.
class AppVersion {
  static const String version = '1.0.1';
  static const int buildNumber = 12;

  /// Full display string, e.g. "1.0.0 (7)"
  static String get display => '$version ($buildNumber)';
}
