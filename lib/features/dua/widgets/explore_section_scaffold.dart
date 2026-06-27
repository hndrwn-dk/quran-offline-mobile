import 'package:flutter/material.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';

/// Sub-screen shell for a Jelajahi hub section (back + title + optional drill context).
class ExploreSectionScaffold extends StatelessWidget {
  const ExploreSectionScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.parentSection,
    required this.body,
  });

  final String title;
  final String? subtitle;

  /// When set, subtitle becomes "$countOrSubtitle · $parentSection" if [subtitle]
  /// looks like a count label; otherwise uses [subtitle] as-is.
  final String? parentSection;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topTint = HomeBackdrop.topTint(colorScheme);

    final resolvedSubtitle = _resolveSubtitle();

    return Scaffold(
      backgroundColor: topTint,
      appBar: AppBar(
        backgroundColor: topTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (resolvedSubtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                resolvedSubtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      body: HomeBackdrop(child: body),
    );
  }

  String? _resolveSubtitle() {
    if (subtitle == null) return null;
    if (parentSection == null || parentSection!.isEmpty) return subtitle;
    return '$subtitle · $parentSection';
  }
}
