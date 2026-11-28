import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/feedback/app_feedback_content.dart';
import 'package:quran_offline/core/feedback/feedback_context.dart';
import 'package:quran_offline/core/feedback/feedback_email_fallback.dart';
import 'package:quran_offline/core/feedback/feedback_type.dart';
import 'package:quran_offline/core/feedback/github_feedback_service.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

Future<void> showFeedbackForm(
  BuildContext context, {
  required FeedbackType type,
  required String language,
  FeedbackContext? contextData,
  String? initialTitle,
  String? initialDescription,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => FeedbackFormSheet(
      type: type,
      language: language,
      contextData: contextData,
      initialTitle: initialTitle,
      initialDescription: initialDescription,
    ),
  );
}

class FeedbackFormSheet extends ConsumerStatefulWidget {
  const FeedbackFormSheet({
    super.key,
    required this.type,
    required this.language,
    this.contextData,
    this.initialTitle,
    this.initialDescription,
  });

  final FeedbackType type;
  final String language;
  final FeedbackContext? contextData;
  final String? initialTitle;
  final String? initialDescription;

  @override
  ConsumerState<FeedbackFormSheet> createState() => _FeedbackFormSheetState();
}

class _FeedbackFormSheetState extends ConsumerState<FeedbackFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _text(String key) =>
      AppLocalizations.getSettingsText(key, widget.language);

  String _formTitle() => switch (widget.type) {
        FeedbackType.feature => _text('feedback_form_title_feature'),
        FeedbackType.bug => _text('feedback_form_title_bug'),
      };

  String _titleHint() => switch (widget.type) {
        FeedbackType.feature => _text('feedback_title_hint_feature'),
        FeedbackType.bug => _text('feedback_title_hint_bug'),
      };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;

    setState(() => _submitting = true);

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final metadata = AppFeedbackContent.buildMetadata(
      language: widget.language,
      context: widget.contextData,
    );

    final service = GitHubFeedbackService();
    final result = await service.submit(
      type: widget.type,
      title: title,
      description: description,
      metadata: metadata,
    );
    service.dispose();

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_text('feedback_success')),
        ),
      );
      return;
    }

    final emailed = await FeedbackEmailFallback.launch(
      type: widget.type,
      language: widget.language,
      title: title,
      description: description,
      context: widget.contextData,
    );

    if (!mounted) return;

    setState(() => _submitting = false);

    if (emailed) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_text('feedback_success_email_fallback')),
        ),
      );
    } else {
      final message = result.errorMessage == 'rate_limited'
          ? _text('feedback_error_rate_limited')
          : _text('feedback_error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  InputDecoration _fieldDecoration(ColorScheme colorScheme, String hint) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colorScheme.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(colorScheme.hairline),
      enabledBorder: border(colorScheme.hairline),
      disabledBorder: border(colorScheme.hairline),
      focusedBorder: border(colorScheme.primary, 1.5),
      errorBorder: border(colorScheme.error),
      focusedErrorBorder: border(colorScheme.error, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final viewHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = (viewHeight * 0.88).clamp(420.0, viewHeight - 24);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: colorScheme.canvas,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.sheetRadius),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      _formTitle(),
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (widget.contextData?.hasVerse == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _text('feedback_body_verse')
                        .replaceAll('{surah}', '${widget.contextData!.surahId}')
                        .replaceAll('{ayah}', '${widget.contextData!.ayahNo}'),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onTint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    Text(
                      _text('feedback_title_label'),
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      enabled: !_submitting,
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration(colorScheme, _titleHint()),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _text('feedback_title_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _text('feedback_description_label'),
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_submitting,
                      maxLength: 8000,
                      minLines: 5,
                      maxLines: 12,
                      textInputAction: TextInputAction.newline,
                      decoration: _fieldDecoration(
                        colorScheme,
                        _text('feedback_description_hint'),
                      ).copyWith(alignLabelWithHint: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _text('feedback_description_required');
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_text('feedback_submitting')),
                          ],
                        )
                      : Text(_text('feedback_submit')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
