import 'package:quran_offline/core/models/tafsir_content.dart';

class TafsirEntry {
  const TafsirEntry({
    required this.content,
    this.rangeLabel,
  });

  final TafsirContent content;
  final String? rangeLabel;

  bool get isEmpty => content.isEmpty;

  String get plainText => content.plainText;
}
