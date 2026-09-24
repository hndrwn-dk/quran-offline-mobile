import 'package:flutter/widgets.dart';

/// Owns a non-primary [ScrollController] and clamps [pixels] after the
/// viewport grows (keyboard closed, nav bar restored).
class InsetClampingScroll extends StatefulWidget {
  const InsetClampingScroll({
    super.key,
    required this.builder,
  });

  final Widget Function(ScrollController controller) builder;

  @override
  State<InsetClampingScroll> createState() => _InsetClampingScrollState();
}

class _InsetClampingScrollState extends State<InsetClampingScroll>
    with WidgetsBindingObserver {
  late final ScrollController _controller;
  double? _lastViewInset;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (_lastViewInset != inset) {
      _lastViewInset = inset;
      _clampAfterLayout();
    }
  }

  @override
  void didChangeMetrics() {
    _clampAfterLayout();
  }

  void _clampAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final pos = _controller.position;
      if (!pos.hasContentDimensions || !pos.hasViewportDimension) return;
      if (pos.pixels > pos.maxScrollExtent) {
        _controller.jumpTo(pos.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_controller);
  }
}
