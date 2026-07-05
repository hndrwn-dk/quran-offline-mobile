import 'dart:convert';

/// JSON snapshot pushed to the home screen widget (Android Glance / iOS WidgetKit).
class BerandaWidgetPayload {
  const BerandaWidgetPayload({
    required this.tagline,
    required this.reflectionLabel,
    required this.reflectionTitle,
    required this.reflectionRef,
    required this.reflectionBadge,
    this.reflectionContext,
    required this.continueLabel,
    this.surahName,
    this.ayahNo,
    this.surahPercent,
    this.juzLabel,
    this.juzPercent,
    this.surahCurrent,
    this.surahTotal,
    this.juzCurrent,
    this.juzTotal,
    required this.readDeepLink,
    required this.reflectionDeepLink,
    required this.hasContinue,
  });

  final String tagline;
  final String reflectionLabel;
  final String reflectionTitle;
  final String reflectionRef;
  final String reflectionBadge;
  final String? reflectionContext;
  final String continueLabel;
  final String? surahName;
  final int? ayahNo;
  final int? surahPercent;
  final String? juzLabel;
  final int? juzPercent;
  final int? surahCurrent;
  final int? surahTotal;
  final int? juzCurrent;
  final int? juzTotal;
  final String readDeepLink;
  final String reflectionDeepLink;
  final bool hasContinue;

  Map<String, dynamic> toJson() => {
        'tagline': tagline,
        'reflectionLabel': reflectionLabel,
        'reflectionTitle': reflectionTitle,
        'reflectionRef': reflectionRef,
        'reflectionBadge': reflectionBadge,
        'reflectionContext': reflectionContext,
        'continueLabel': continueLabel,
        'surahName': surahName,
        'ayahNo': ayahNo,
        'surahPercent': surahPercent,
        'juzLabel': juzLabel,
        'juzPercent': juzPercent,
        'surahCurrent': surahCurrent,
        'surahTotal': surahTotal,
        'juzCurrent': juzCurrent,
        'juzTotal': juzTotal,
        'readDeepLink': readDeepLink,
        'reflectionDeepLink': reflectionDeepLink,
        'hasContinue': hasContinue,
      };

  factory BerandaWidgetPayload.fromJson(Map<String, dynamic> json) {
    return BerandaWidgetPayload(
      tagline: json['tagline'] as String? ?? '',
      reflectionLabel: json['reflectionLabel'] as String? ?? '',
      reflectionTitle: json['reflectionTitle'] as String? ?? '',
      reflectionRef: json['reflectionRef'] as String? ?? '',
      reflectionBadge: json['reflectionBadge'] as String? ?? '',
      reflectionContext: json['reflectionContext'] as String?,
      continueLabel: json['continueLabel'] as String? ?? '',
      surahName: json['surahName'] as String?,
      ayahNo: json['ayahNo'] as int?,
      surahPercent: json['surahPercent'] as int?,
      juzLabel: json['juzLabel'] as String?,
      juzPercent: json['juzPercent'] as int?,
      surahCurrent: json['surahCurrent'] as int?,
      surahTotal: json['surahTotal'] as int?,
      juzCurrent: json['juzCurrent'] as int?,
      juzTotal: json['juzTotal'] as int?,
      readDeepLink: json['readDeepLink'] as String? ?? 'quranoffline://home',
      reflectionDeepLink:
          json['reflectionDeepLink'] as String? ?? 'quranoffline://reflection',
      hasContinue: json['hasContinue'] as bool? ?? false,
    );
  }

  String encode() => jsonEncode(toJson());

  static BerandaWidgetPayload decode(String raw) {
    return BerandaWidgetPayload.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
