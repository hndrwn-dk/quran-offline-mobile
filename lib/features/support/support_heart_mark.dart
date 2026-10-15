import 'package:flutter/material.dart';

/// Filled heart on a primary container circle. Theme tokens only.
class SupportHeartMark extends StatelessWidget {
  const SupportHeartMark({
    super.key,
    required this.circleSize,
    required this.iconSize,
    this.dimInDark = false,
  });

  final double circleSize;
  final double iconSize;

  /// App-bar chip only. Dark primaryContainer is a solid shade, so it is
  /// drawn at 60% opacity and stays quieter than the page title.
  final bool dimInDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dim = dimInDark && colorScheme.brightness == Brightness.dark;
    final background = dim
        ? colorScheme.primaryContainer.withValues(alpha: 0.6)
        : colorScheme.primaryContainer;
    return SizedBox(
      width: circleSize,
      height: circleSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.favorite_rounded,
            size: iconSize,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Beranda action. The painted circle is 36; the button stays 48 for touch.
class SupportAppBarButton extends StatelessWidget {
  const SupportAppBarButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        minimumSize: const Size(48, 48),
        maximumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const SupportHeartMark(
        circleSize: 36,
        iconSize: 20,
        dimInDark: true,
      ),
    );
  }
}

/// One-time thanks pop. Holds the final frame when animations are disabled.
class SupportThanksHeart extends StatefulWidget {
  const SupportThanksHeart({super.key});

  @override
  State<SupportThanksHeart> createState() => _SupportThanksHeartState();
}

class _SupportThanksHeartState extends State<SupportThanksHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.08).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 35,
      ),
    ]).animate(_controller);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: const SupportHeartMark(circleSize: 72, iconSize: 36),
      ),
    );
  }
}
