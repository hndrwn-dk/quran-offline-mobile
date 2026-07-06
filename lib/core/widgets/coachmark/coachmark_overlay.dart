import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quran_offline/core/widgets/coachmark/coachmark_spotlight_painter.dart';
import 'package:quran_offline/core/widgets/coachmark/coachmark_style.dart';

/// Full-screen coachmark overlay with spotlight, pulse ring, and tooltip bubble.
class CoachmarkOverlay {
  CoachmarkOverlay._();

  static OverlayEntry? _entry;

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String title,
    required String body,
    required String dismissLabel,
    required String ctaLabel,
    required VoidCallback onDismiss,
    required VoidCallback onCta,
  }) {
    hide();

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _CoachmarkOverlayBody(
        targetKey: targetKey,
        title: title,
        body: body,
        dismissLabel: dismissLabel,
        ctaLabel: ctaLabel,
        onDismiss: () {
          hide();
          onDismiss();
        },
        onCta: () {
          hide();
          onCta();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _CoachmarkOverlayBody extends StatefulWidget {
  const _CoachmarkOverlayBody({
    required this.targetKey,
    required this.title,
    required this.body,
    required this.dismissLabel,
    required this.ctaLabel,
    required this.onDismiss,
    required this.onCta,
  });

  final GlobalKey targetKey;
  final String title;
  final String body;
  final String dismissLabel;
  final String ctaLabel;
  final VoidCallback onDismiss;
  final VoidCallback onCta;

  @override
  State<_CoachmarkOverlayBody> createState() => _CoachmarkOverlayBodyState();
}

class _CoachmarkOverlayBodyState extends State<_CoachmarkOverlayBody>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _tooltipController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _tooltipFadeAnimation;
  late final Animation<Offset> _tooltipSlideAnimation;

  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: CoachmarkStyle.fadeDuration,
    );
    _tooltipController = AnimationController(
      vsync: this,
      duration: CoachmarkStyle.fadeDuration,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: CoachmarkStyle.pulseDuration,
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _tooltipFadeAnimation = CurvedAnimation(
      parent: _tooltipController,
      curve: Curves.easeOut,
    );
    _tooltipSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _tooltipController,
        curve: Curves.easeOut,
      ),
    );

    _fadeController.forward();
    Future<void>.delayed(CoachmarkStyle.tooltipDelay, () {
      if (mounted) _tooltipController.forward();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTargetRect());
  }

  void _resolveTargetRect() {
    final rect = _rectForKey(widget.targetKey);
    if (rect == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolveTargetRect());
      return;
    }
    if (!mounted) return;
    setState(() => _targetRect = rect);
  }

  Rect? _rectForKey(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tooltipController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetRect = _targetRect;
    final media = MediaQuery.of(context);

    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (targetRect != null) ...[
              FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onDismiss,
                  child: CustomPaint(
                    size: media.size,
                    painter: CoachmarkSpotlightPainter(targetRect: targetRect),
                  ),
                ),
              ),
              _PulseRing(
                controller: _pulseController,
                targetRect: targetRect,
              ),
              _CoachmarkTooltip(
                targetRect: targetRect,
                title: widget.title,
                body: widget.body,
                dismissLabel: widget.dismissLabel,
                ctaLabel: widget.ctaLabel,
                fadeAnimation: _tooltipFadeAnimation,
                slideAnimation: _tooltipSlideAnimation,
                onDismiss: widget.onDismiss,
                onCta: widget.onCta,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.controller,
    required this.targetRect,
  });

  final AnimationController controller;
  final Rect targetRect;

  @override
  Widget build(BuildContext context) {
    final holeRect = targetRect.inflate(CoachmarkStyle.spotlightPadding);

    return Positioned(
      left: holeRect.left,
      top: holeRect.top,
      width: holeRect.width,
      height: holeRect.height,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final t = controller.value;
          final scale = 0.9 + (0.45 * t);
          final opacity = (0.7 * (1 - t)).clamp(0.0, 0.7);

          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    CoachmarkStyle.spotlightBorderRadius,
                  ),
                  border: Border.all(
                    color: CoachmarkStyle.pulseRing,
                    width: 2,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoachmarkTooltip extends StatelessWidget {
  const _CoachmarkTooltip({
    required this.targetRect,
    required this.title,
    required this.body,
    required this.dismissLabel,
    required this.ctaLabel,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.onDismiss,
    required this.onCta,
  });

  final Rect targetRect;
  final String title;
  final String body;
  final String dismissLabel;
  final String ctaLabel;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final VoidCallback onDismiss;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    const tooltipWidth = CoachmarkStyle.tooltipWidth;
    final holeRect = targetRect.inflate(CoachmarkStyle.spotlightPadding);

    final right = math.max(
      16.0,
      media.size.width - holeRect.right - 8,
    );
    final left = media.size.width - tooltipWidth - right;
    final top = holeRect.bottom + 10;

    return Positioned(
      left: left.clamp(16.0, media.size.width - tooltipWidth - 16),
      top: top,
      width: tooltipWidth,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: GestureDetector(
            onTap: () {},
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -8,
                  right: 34,
                  child: Transform.rotate(
                    angle: math.pi / 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: CoachmarkStyle.tooltipBackground,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: CoachmarkStyle.tooltipBackground,
                    borderRadius: BorderRadius.circular(
                      CoachmarkStyle.tooltipBorderRadius,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 30,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: CoachmarkStyle.tooltipInk,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: const TextStyle(
                            color: CoachmarkStyle.tooltipBody,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: CoachmarkStyle.tooltipDismiss,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: onDismiss,
                              child: Text(
                                dismissLabel,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: CoachmarkStyle.tooltipBackground,
                                backgroundColor: CoachmarkStyle.tooltipInk,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: onCta,
                              child: Text(
                                ctaLabel,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
