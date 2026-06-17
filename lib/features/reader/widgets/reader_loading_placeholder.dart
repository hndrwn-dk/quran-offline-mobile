import 'package:flutter/material.dart';

/// Skeleton list while [readerVersesProvider] loads (Juz / Surah reader).
class ReaderLoadingPlaceholder extends StatelessWidget {
  const ReaderLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final block = colorScheme.onSurface.withValues(alpha: 0.06);
    final line = colorScheme.onSurface.withValues(alpha: 0.08);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (index == 0 || index == 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: block,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: line,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 40,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: block,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
