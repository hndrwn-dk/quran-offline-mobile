/// Application version info. Keep in sync with pubspec.yaml version.
class AppVersion {
  static const String version = '1.0.5';
  static const int buildNumber = 31;

  /// Full display string, e.g. "1.0.1 (18)"
  static String get display => '$version ($buildNumber)';
}
