import 'package:json_annotation/json_annotation.dart';

part 'verse_model.g.dart';

@JsonSerializable()
class VerseModel {
  @JsonKey(name: 's')
  final int s;
  @JsonKey(name: 'a')
  final int a;
  @JsonKey(name: 'ar')
  final String ar;
  @JsonKey(name: 'tl')
  final String? tl;
  @JsonKey(name: 'tr')
  final Map<String, String>? tr;
  @JsonKey(name: 'm')
  final VerseMetadata? m;

  VerseModel({
    required this.s,
    required this.a,
    required this.ar,
    this.tl,
    this.tr,
    this.m,
  });

  int get surahId => s;
  int get ayahNo => a;
  String get arabic => ar;
  String? get translit => tl;
  Map<String, String>? get translations => tr;
  VerseMetadata? get metadata => m;

  factory VerseModel.fromJson(Map<String, dynamic> json) => _$VerseModelFromJson(json);
  Map<String, dynamic> toJson() => _$VerseModelToJson(this);
}

@JsonSerializable()
class VerseMetadata {
  @JsonKey(name: 'juz')
  final int? juz;
  @JsonKey(name: 'page')
  final int? page;
  @JsonKey(name: 'hizb')
  final int? hizb;
  @JsonKey(name: 'ruku')
  final int? ruku;

  VerseMetadata({
    this.juz,
    this.page,
    this.hizb,
    this.ruku,
  });

  factory VerseMetadata.fromJson(Map<String, dynamic> json) => _$VerseMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$VerseMetadataToJson(this);
}

