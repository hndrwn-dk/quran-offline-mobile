import 'package:flutter/material.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/notes_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/reader/widgets/reader_app_bar.dart';

class NoteEditorDialog extends ConsumerStatefulWidget {
  final int surahId;
  final int ayahNo;
  final String? existingNote;

  const NoteEditorDialog({
    super.key,
    required this.surahId,
    required this.ayahNo,
    this.existingNote,
  });

  @override
  ConsumerState<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends ConsumerState<NoteEditorDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_controller.text.trim().isEmpty) {
      // Delete note if empty
      await deleteNote(ref, widget.surahId, widget.ayahNo);
    } else {
      await saveNote(ref, widget.surahId, widget.ayahNo, _controller.text.trim());
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.getSettingsText('delete_note_title', ref.read(settingsProvider).appLanguage)),
        content: Text(AppLocalizations.getSettingsText('delete_note_message', ref.read(settingsProvider).appLanguage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.getSettingsText('cancel', ref.read(settingsProvider).appLanguage)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.getSettingsText('delete', ref.read(settingsProvider).appLanguage)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      await deleteNote(ref, widget.surahId, widget.ayahNo);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              AppLocalizations.getSettingsText('note_title', appLanguage),
            ),
          ),
          Text(
            '${widget.surahId}:${widget.ayahNo}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 16, 16),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          maxLines: 8,
          minLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.getSettingsText('note_hint', appLanguage),
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colorScheme.hairline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),
      ),
      actions: [
        if (widget.existingNote != null)
          TextButton.icon(
            onPressed: _isSaving ? null : _deleteNote,
            icon: const Icon(Icons.delete_outline, size: 20),
            label: Text(AppLocalizations.getSettingsText('delete', appLanguage)),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.tint,
            foregroundColor: readerOnTint(colorScheme),
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: const StadiumBorder(),
          ),
          child: Text(AppLocalizations.getSettingsText('cancel', appLanguage)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          onPressed: _isSaving ? null : _saveNote,
          child: Text(AppLocalizations.getSettingsText('save', appLanguage)),
        ),
      ],
    );
  }
}

