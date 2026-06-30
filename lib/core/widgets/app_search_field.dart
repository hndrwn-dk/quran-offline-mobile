import 'package:flutter/material.dart';

/// Standard horizontal inset for search fields and list cards on tab screens.
const double kAppContentHorizontalInset = 16;

/// Vertical gap between AppBar divider and first body control (search, segments, list).
const double kAppBodyTopInset = 8;

/// Shared premium search field — same width, border, and trailing affordance app-wide.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.autofocus = false,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.textInputAction = TextInputAction.search,
    this.textFieldKey,
  });

  final TextEditingController controller;
  final String hintText;
  final FocusNode? focusNode;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final Key? textFieldKey;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasText = widget.controller.text.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 4, hasText ? 4 : 4, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: widget.textFieldKey,
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  textInputAction: widget.textInputAction,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 9,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              if (hasText)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                  onPressed: _clear,
                )
              else
                Material(
                  color: colorScheme.onSurface,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => widget.focusNode?.requestFocus(),
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.search,
                        size: 20,
                        color: colorScheme.surface,
                      ),
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

/// Wraps [AppSearchField] with standard horizontal inset and vertical spacing.
class AppSearchFieldInset extends StatelessWidget {
  const AppSearchFieldInset({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(
      kAppContentHorizontalInset,
      kAppBodyTopInset,
      kAppContentHorizontalInset,
      8,
    ),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}
