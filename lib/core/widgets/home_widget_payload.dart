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
    this.continueTitle,
    this.continueMeta,
    this.continueButton,
    this.continuePercent,
    this.continueDescription,
    this.continueHint,
    this.ayahRef,
    this.ayahTranslation,
    this.ayahPosition,
    this.ayahDeepLink,
    this.reflectionButton,
    this.ayahImageMedium,
    this.ayahImageLarge,
    this.updatedAt,
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

  // Responsive widget (small / medium / large).
  final String? continueTitle;
  final String? continueMeta;
  final String? continueButton;
  final int? continuePercent;
  final String? continueDescription;
  final String? continueHint;
  final String? ayahRef;
  final String? ayahTranslation;
  final String? ayahPosition;
  final String? ayahDeepLink;
  final String? reflectionButton;
  final String? ayahImageMedium;
  final String? ayahImageLarge;

  /// Changes on every sync so Glance recomposes and reloads the ayah PNGs,
  /// which keep their paths when re-rendered.
  final int? updatedAt;

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
        'continueTitle': continueTitle,
        'continueMeta': continueMeta,
        'continueButton': continueButton,
        'continuePercent': continuePercent,
        'continueDescription': continueDescription,
        'continueHint': continueHint,
        'ayahRef': ayahRef,
        'ayahTranslation': ayahTranslation,
        'ayahPosition': ayahPosition,
        'ayahDeepLink': ayahDeepLink,
        'reflectionButton': reflectionButton,
        'ayahImageMedium': ayahImageMedium,
        'ayahImageLarge': ayahImageLarge,
        'updatedAt': updatedAt,
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
      continueTitle: json['continueTitle'] as String?,
      continueMeta: json['continueMeta'] as String?,
      continueButton: json['continueButton'] as String?,
      continuePercent: json['continuePercent'] as int?,
      continueDescription: json['continueDescription'] as String?,
      continueHint: json['continueHint'] as String?,
      ayahRef: json['ayahRef'] as String?,
      ayahTranslation: json['ayahTranslation'] as String?,
      ayahPosition: json['ayahPosition'] as String?,
      ayahDeepLink: json['ayahDeepLink'] as String?,
      reflectionButton: json['reflectionButton'] as String?,
      ayahImageMedium: json['ayahImageMedium'] as String?,
      ayahImageLarge: json['ayahImageLarge'] as String?,
      updatedAt: json['updatedAt'] as int?,
    );
  }

  String encode() => jsonEncode(toJson());

  static BerandaWidgetPayload decode(String raw) {
    return BerandaWidgetPayload.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}
