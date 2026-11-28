import 'package:flutter/material.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';

class AboutDataSourcesTile extends StatelessWidget {
  const AboutDataSourcesTile({super.key, required this.appLanguage});

  final String appLanguage;

  TextStyle _bodyStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          height: 1.45,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const AppBadge(icon: Icons.library_books_outlined, size: 38),
        title: Text(
          AppLocalizations.getSettingsText('data_sources_title', appLanguage),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.getSettingsText('credits_line1', appLanguage),
                  textAlign: TextAlign.start,
                  style: _bodyStyle(context),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.getSettingsText('credits_line2', appLanguage),
                  textAlign: TextAlign.start,
                  style: _bodyStyle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
