import 'package:flutter/material.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

Future<void> showLibraryActionSheet({
  required BuildContext context,
  required String title,
  String? preview,
  required String language,
  required VoidCallback onOpen,
  VoidCallback? onEdit,
  required String copyLabel,
  required VoidCallback onCopy,
  required String deleteLabel,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                    ),
                    if (preview != null && preview.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        preview.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(AppLocalizations.libraryOpenInReader(language)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onOpen();
                },
              ),
              if (onEdit != null)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(AppLocalizations.libraryEditNote(language)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onEdit();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(copyLabel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onCopy();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: colorScheme.error),
                title: Text(
                  deleteLabel,
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
