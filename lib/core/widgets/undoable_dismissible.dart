import 'package:flutter/material.dart';

/// Swipe-left row that reveals a destructive action.
///
/// The caller removes the child from the tree inside [onDismissed] and offers
/// undo through [showUndoSnackBar].
class UndoableDismissible extends StatelessWidget {
  const UndoableDismissible({
    super.key,
    required this.dismissKey,
    required this.child,
    required this.onDismissed,
    required this.backgroundLabel,
    this.backgroundIcon = Icons.delete_outline,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final Key dismissKey;
  final Widget child;
  final VoidCallback onDismissed;
  final String backgroundLabel;
  final IconData backgroundIcon;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: borderRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(backgroundIcon, color: colorScheme.onError),
            const SizedBox(width: 8),
            Text(
              backgroundLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onError,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}

void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: actionLabel,
        onPressed: onAction,
      ),
    ),
  );
}
