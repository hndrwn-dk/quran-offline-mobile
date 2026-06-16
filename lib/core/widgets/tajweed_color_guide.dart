import 'package:flutter/material.dart';
import 'package:quran_offline/core/tajweed/tajweed_colors.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

typedef TajweedGuideRule = ({String nameKey, String descKey, String colorClass});

/// Tajweed color legend aligned with [TajweedColors] / Quran.com markup.
class TajweedColorGuide {
  TajweedColorGuide._();

  static const List<TajweedGuideRule> rules = [
    (nameKey: 'tajweed_rule_ikhfa', descKey: 'tajweed_rule_ikhfa_desc', colorClass: 'ikhfa'),
    (nameKey: 'tajweed_rule_idgham', descKey: 'tajweed_rule_idgham_desc', colorClass: 'idgham_ghunnah'),
    (nameKey: 'tajweed_rule_iqlab', descKey: 'tajweed_rule_iqlab_desc', colorClass: 'iqlab'),
    (nameKey: 'tajweed_rule_ghunnah', descKey: 'tajweed_rule_ghunnah_desc', colorClass: 'ghunnah'),
    (nameKey: 'tajweed_rule_qalqalah', descKey: 'tajweed_rule_qalqalah_desc', colorClass: 'qalqalah'),
    (nameKey: 'tajweed_rule_tafkhim', descKey: 'tajweed_rule_tafkhim_desc', colorClass: 'tafkhim'),
    (nameKey: 'tajweed_rule_laam_shamsiyah', descKey: 'tajweed_rule_laam_shamsiyah_desc', colorClass: 'laam_shamsiyah'),
    (nameKey: 'tajweed_rule_madd', descKey: 'tajweed_rule_madd_desc', colorClass: 'madda_normal'),
    (nameKey: 'tajweed_rule_madd_wajib_munfasil', descKey: 'tajweed_rule_madd_wajib_munfasil_desc', colorClass: 'madda_obligatory'),
    (nameKey: 'tajweed_rule_madd_wajib_muttasil', descKey: 'tajweed_rule_madd_wajib_muttasil_desc', colorClass: 'madda_obligatory_mottasel'),
    (nameKey: 'tajweed_rule_madd_lazim', descKey: 'tajweed_rule_madd_lazim_desc', colorClass: 'madda_necessary'),
    (nameKey: 'tajweed_rule_ham_wasl', descKey: 'tajweed_rule_ham_wasl_desc', colorClass: 'ham_wasl'),
  ];
}

class TajweedColorGuideContent extends StatelessWidget {
  const TajweedColorGuideContent({
    super.key,
    required this.appLanguage,
  });

  final String appLanguage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color ruleColor(String key) => TajweedColors.colorForClassWithTheme(
          key,
          isDark: isDark,
          colorScheme: colorScheme,
          defaultColor: colorScheme.onSurface,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in TajweedColorGuide.rules)
          TajweedColorGuideRuleItem(
            name: AppLocalizations.getSettingsText(rule.nameKey, appLanguage),
            description: AppLocalizations.getSettingsText(rule.descKey, appLanguage),
            color: ruleColor(rule.colorClass),
          ),
      ],
    );
  }
}

class TajweedColorGuideRuleItem extends StatelessWidget {
  const TajweedColorGuideRuleItem({
    super.key,
    required this.name,
    required this.description,
    required this.color,
  });

  final String name;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
