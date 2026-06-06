/// Application version info. Keep in sync with pubspec.yaml version.
class AppVersion {
  static const String version = '1.0.1';
  static const int buildNumber = 17;

  /// Full display string, e.g. "1.0.1 (17)"
  static String get display => '$version ($buildNumber)';
}
