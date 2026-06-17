import 'package:flutter/material.dart';

/// Skeleton shown while a Mushaf page font + layout rows are loading.
class MushafPageLoadingPlaceholder extends StatelessWidget {
  const MushafPageLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lineColor = colorScheme.onSurface.withValues(alpha: 0.07);

    return Column(
      children: [
        for (var i = 0; i < 14; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.55 + (i % 4) * 0.1,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
