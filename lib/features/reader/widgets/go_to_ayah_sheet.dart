import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

const int kAyatKursiSurahId = 2;
const int kAyatKursiAyahNo = 255;

/// AppBar chip for jumping to a verse — matches surah meta / recitation bar styling.
class GoToAyahAppBarChip extends StatelessWidget {
  const GoToAyahAppBarChip({
    super.key,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tag,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoToAyahShortcut {
  const GoToAyahShortcut({required this.label, required this.ayahNo});

  final String label;
  final int ayahNo;
}

List<GoToAyahShortcut> buildGoToAyahShortcuts({
  required String language,
  required int surahId,
  required int verseCount,
}) {
  final shortcuts = <GoToAyahShortcut>[
    GoToAyahShortcut(
      label: AppLocalizations.getGoToAyahShortcutStart(language),
      ayahNo: 1,
    ),
  ];
  if (surahId == kAyatKursiSurahId && verseCount >= kAyatKursiAyahNo) {
    shortcuts.add(
      GoToAyahShortcut(
        label: AppLocalizations.getGoToAyahShortcutKursi(language),
        ayahNo: kAyatKursiAyahNo,
      ),
    );
  }
  final middle = (verseCount / 2).ceil().clamp(1, verseCount);
  if (middle != 1 && middle != verseCount) {
    shortcuts.add(
      GoToAyahShortcut(
        label: AppLocalizations.getGoToAyahShortcutMiddle(language),
        ayahNo: middle,
      ),
    );
  }
  shortcuts.add(
    GoToAyahShortcut(
      label: AppLocalizations.getGoToAyahShortcutEnd(language),
      ayahNo: verseCount,
    ),
  );
  return shortcuts;
}

Future<void> showGoToAyahSheet(
  BuildContext context, {
  required String surahName,
  required int surahId,
  required int currentAyah,
  required int verseCount,
  required ValueChanged<int> onJump,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => GoToAyahSheet(
      surahName: surahName,
      surahId: surahId,
      currentAyah: currentAyah,
      verseCount: verseCount,
      onJump: onJump,
    ),
  );
}

class GoToAyahSheet extends ConsumerStatefulWidget {
  const GoToAyahSheet({
    super.key,
    required this.surahName,
    required this.surahId,
    required this.currentAyah,
    required this.verseCount,
    required this.onJump,
  });

  final String surahName;
  final int surahId;
  final int currentAyah;
  final int verseCount;
  final ValueChanged<int> onJump;

  @override
  ConsumerState<GoToAyahSheet> createState() => _GoToAyahSheetState();
}

class _GoToAyahSheetState extends ConsumerState<GoToAyahSheet> {
  late final TextEditingController _controller;
  late int _selectedAyah;

  @override
  void initState() {
    super.initState();
    _selectedAyah = widget.currentAyah.clamp(1, widget.verseCount);
    _controller = TextEditingController(text: '$_selectedAyah');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setAyah(int ayah) {
    final clamped = ayah.clamp(1, widget.verseCount);
    setState(() {
      _selectedAyah = clamped;
      _controller.text = '$clamped';
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  void _applyFromField() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      _setAyah(_selectedAyah);
      return;
    }
    _setAyah(parsed);
  }

  void _jump() {
    _applyFromField();
    widget.onJump(_selectedAyah);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    final shortcuts = buildGoToAyahShortcuts(
      language: appLanguage,
      surahId: widget.surahId,
      verseCount: widget.verseCount,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.getGoToAyahSheetTitle(appLanguage),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.surahName,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.formatGoToAyahSheetHint(
                  appLanguage,
                  widget.currentAyah,
                  widget.verseCount,
                ),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _selectedAyah > 1
                        ? () => _setAyah(_selectedAyah - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _applyFromField(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: _selectedAyah < widget.verseCount
                        ? () => _setAyah(_selectedAyah + 1)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shortcuts.map((shortcut) {
                  final selected = shortcut.ayahNo == _selectedAyah;
                  return FilterChip(
                    label: Text(
                      shortcut.ayahNo == 1 ||
                              (shortcut.ayahNo == kAyatKursiAyahNo &&
                                  widget.surahId == kAyatKursiSurahId)
                          ? shortcut.label
                          : '${shortcut.label} (${shortcut.ayahNo})',
                    ),
                    selected: selected,
                    onSelected: (_) => _setAyah(shortcut.ayahNo),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _jump,
                child: Text(
                  AppLocalizations.formatGoToAyahJump(
                    appLanguage,
                    _selectedAyah,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
