/// Prefix-based SharedPreferences keys so one app can host multiple coachmarks.
class CoachmarkStorageKeys {
  const CoachmarkStorageKeys({required this.prefix});

  final String prefix;

  String get showCount => '${prefix}_show_count';
  String get lastShownAt => '${prefix}_last_shown_at';
  String get hasTappedCta => '${prefix}_has_tapped_cta';
}
