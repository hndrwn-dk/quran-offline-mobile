import 'package:flutter/material.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/home/widgets/home_cta_buttons.dart';

/// Sub-screen shell for a Jelajahi hub section (back + title + optional drill context).
class ExploreSectionScaffold extends StatelessWidget {
  const ExploreSectionScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.parentSection,
    this.actions,
    required this.body,
  });

  final String title;
  final String? subtitle;

  /// When set, subtitle becomes "$countOrSubtitle · $parentSection" if [subtitle]
  /// looks like a count label; otherwise uses [subtitle] as-is.
  final String? parentSection;
  final List<Widget>? actions;
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
        automaticallyImplyLeading: false,
        leading: HomeCircleArrowButton.maybeAppBarBack(context),
        backgroundColor: topTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: HomeBackdrop.overlayStyle(colorScheme),
        flexibleSpace: HomeBackdrop.cornerArcFlexibleSpace(colorScheme),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
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
        actions: actions,
      ),
      body: HomeBackdrop(
        child: Padding(
          padding: const EdgeInsets.only(top: kAppBodyTopInset),
          child: body,
        ),
      ),
    );
  }

  String? _resolveSubtitle() {
    if (subtitle == null) return null;
    if (parentSection == null || parentSection!.isEmpty) return subtitle;
    return '$subtitle · $parentSection';
  }
}
