import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/widgets/quran_arabic_text.dart';

class ArabicSnippetCache {
  static final Map<String, String> memory = <String, String>{};

  static Future<String?> textFor({
    required int surah,
    required int ayah,
    required Future<String?> Function(int surah, int ayah) lookup,
  }) async {
    final key = '$surah:$ayah';
    final hit = memory[key];
    if (hit != null) return hit;
    final loaded = await lookup(surah, ayah);
    if (loaded == null || loaded.isEmpty) return null;
    memory[key] = loaded;
    return loaded;
  }
}

final arabicSnippetLookupProvider =
    Provider<Future<String?> Function(int surah, int ayah)>((ref) {
  final db = ref.watch(databaseProvider);
  return (surah, ayah) {
    return ArabicSnippetCache.textFor(
      surah: surah,
      ayah: ayah,
      lookup: (s, a) async => (await db.getVerse(s, a))?.arabic,
    );
  };
});

class ArabicSnippet extends ConsumerStatefulWidget {
  const ArabicSnippet({
    super.key,
    this.arabic,
    this.surah,
    this.ayah,
    this.large = false,
  });

  final String? arabic;
  final int? surah;
  final int? ayah;
  final bool large;

  @override
  ConsumerState<ArabicSnippet> createState() => _ArabicSnippetState();
}

class _ArabicSnippetState extends ConsumerState<ArabicSnippet> {
  String? _text;

  @override
  void initState() {
    super.initState();
    _text = widget.arabic;
    if (widget.arabic == null) _load();
  }

  @override
  void didUpdateWidget(ArabicSnippet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.arabic != oldWidget.arabic ||
        widget.surah != oldWidget.surah ||
        widget.ayah != oldWidget.ayah) {
      _text = widget.arabic;
      if (widget.arabic == null) _load();
    }
  }

  Future<void> _load() async {
    final surah = widget.surah;
    final ayah = widget.ayah;
    if (surah == null || ayah == null) return;
    final lookup = ref.read(arabicSnippetLookupProvider);
    final text = await lookup(surah, ayah);
    if (!mounted || widget.arabic != null) return;
    setState(() => _text = text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = widget.large ? 26.0 : 18.0;
    final color = widget.large
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;
    return SizedBox(
      height: fontSize * 1.35,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          _text ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.rtl,
          style: QuranArabicText.arabicDisplayStyle(
            fontSize: fontSize,
            color: color,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
