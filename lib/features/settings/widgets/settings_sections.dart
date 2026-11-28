import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/app/app_theme.dart';
import 'package:quran_offline/core/audio/audio_offline_prompts.dart';
import 'package:quran_offline/core/models/reciter.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/package_info_provider.dart';
import 'package:quran_offline/core/providers/reciter_provider.dart';
import 'package:quran_offline/core/mushaf/mushaf_page_geometry.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/feedback/feedback_context.dart';
import 'package:quran_offline/core/feedback/feedback_email_fallback.dart';
import 'package:quran_offline/core/feedback/feedback_type.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_surface.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_turn_picker.dart';
import 'package:quran_offline/features/settings/feedback_form_sheet.dart';
import 'package:quran_offline/features/settings/audio_downloads_screen.dart';
import 'package:quran_offline/features/settings/settings_link_actions.dart';
import 'package:quran_offline/features/settings/widgets/about_data_sources_tile.dart';
import 'package:quran_offline/features/support/support_sheet.dart';

String settingsLanguageName(String lang) {
  return switch (lang) {
    'id' => 'Indonesian',
    'en' => 'English',
    'zh' => 'Chinese',
    'ja' => 'Japanese',
    _ => lang,
  };
}

String settingsThemeModeName(ThemeMode mode, String language) {
  return switch (mode) {
    ThemeMode.system => AppLocalizations.getSettingsText('theme_system', language),
    ThemeMode.light => AppLocalizations.getSettingsText('theme_light', language),
    ThemeMode.dark => AppLocalizations.getSettingsText('theme_dark', language),
  };
}

IconData settingsThemeModeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => Icons.light_mode,
    ThemeMode.dark => Icons.dark_mode,
    ThemeMode.system => Icons.brightness_auto,
  };
}

/// Section title shown inside a [SettingsSectionCard].
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              // Primary in light; the brighter on-tint green in dark.
              color: Theme.of(context).colorScheme.onTint,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// One settings section: a flat card with its title inside, then the rows.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: ListTileTheme.merge(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          horizontalTitleGap: 14,
          minVerticalPadding: 9,
          iconColor: colorScheme.onSurfaceVariant,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSectionHeader(title: title),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Leading icon badge of a settings row.
class SettingsRowBadge extends StatelessWidget {
  const SettingsRowBadge(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => AppBadge(icon: icon, size: 38);
}

Widget _rowTitle(BuildContext context, String text) {
  final theme = Theme.of(context);
  return Text(
    text,
    style: theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    ),
  );
}

TextStyle? _rowSubtitleStyle(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodySmall?.copyWith(
    fontSize: 13,
    height: 1.35,
    color: theme.colorScheme.onSurfaceVariant,
  );
}

class SettingsQuranSection extends ConsumerWidget {
  const SettingsQuranSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSectionCard(
      title: AppLocalizations.getSettingsText('quran_settings_header', appLanguage),
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const SettingsRowBadge(Icons.language),
            title: _rowTitle(context, AppLocalizations.getSettingsText('language_title', appLanguage)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settingsLanguageName(settings.language),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  AppLocalizations.getSettingsText('language_subtitle', appLanguage),
                  style: _rowSubtitleStyle(context),
                ),
              ],
            ),
            childrenPadding: EdgeInsets.zero,
            children: ['id', 'en', 'zh', 'ja'].map((lang) {
              final descKey = switch (lang) {
                'id' => 'language_indonesian_desc',
                'en' => 'language_english_desc',
                'zh' => 'language_chinese_desc',
                'ja' => 'language_japanese_desc',
                _ => 'language_indonesian_desc',
              };
              return ListTile(
                leading: Icon(
                  Icons.translate,
                  color: settings.language == lang
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                title: Text(settingsLanguageName(lang)),
                subtitle: Text(
                  AppLocalizations.getSettingsText(descKey, appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
                trailing: Radio<String>(
                  value: lang,
                  groupValue: settings.language,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateLocale(value);
                    }
                  },
                ),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                onTap: () {
                  ref.read(settingsProvider.notifier).updateLocale(lang);
                },
              );
            }).toList(),
          ),
        ),
        ListTile(
          leading: const SettingsRowBadge(Icons.text_fields),
          title: _rowTitle(
            context,
            AppLocalizations.getSettingsText('show_transliteration_title', appLanguage),
          ),
          subtitle: Text(
            AppLocalizations.getSettingsText('show_transliteration_subtitle', appLanguage),
            style: _rowSubtitleStyle(context),
          ),
          trailing: Switch(
            value: settings.showTransliteration,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTransliteration(value);
            },
          ),
        ),
        ListTile(
          leading: const SettingsRowBadge(Icons.translate),
          title: _rowTitle(
            context,
            AppLocalizations.getSettingsText('show_translation_title', appLanguage),
          ),
          subtitle: Text(
            AppLocalizations.getSettingsText('show_translation_subtitle', appLanguage),
            style: _rowSubtitleStyle(context),
          ),
          trailing: Switch(
            value: settings.showTranslation,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTranslation(value);
            },
          ),
        ),
        ListTile(
          leading: const SettingsRowBadge(Icons.menu_book_outlined),
          title: _rowTitle(context, AppLocalizations.getSettingsText('show_tafsir_title', appLanguage)),
          subtitle: Text(
            AppLocalizations.getSettingsText('show_tafsir_subtitle', appLanguage),
            style: _rowSubtitleStyle(context),
          ),
          trailing: Switch(
            value: settings.showTafsir,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowTafsir(value);
            },
          ),
        ),
        // Also in the Mushaf text settings (framed); phones only have it here.
        ListTile(
          titleAlignment: ListTileTitleAlignment.top,
          leading: const SettingsRowBadge(Icons.auto_stories),
          title: _rowTitle(context, AppLocalizations.getSettingsText('page_turn_title', appLanguage)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.getSettingsText('page_turn_subtitle', appLanguage),
                  style: _rowSubtitleStyle(context),
                ),
                const SizedBox(height: 8),
                MushafPageTurnPicker(
                  value: settings.pageTurnFor(
                    framed: MediaQuery.sizeOf(context).width >=
                        kMushafMinSpreadWindowWidth,
                  ),
                  language: appLanguage,
                  onChanged: (turn) => ref
                      .read(settingsProvider.notifier)
                      .updateMushafPageTurn(turn),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsRecitationSection extends ConsumerWidget {
  const SettingsRecitationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    final selected = ref.watch(reciterProvider);

    return SettingsSectionCard(
      title: AppLocalizations.getRecitationText('recitation_section', appLanguage),
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const SettingsRowBadge(Icons.headphones),
            title: _rowTitle(context, AppLocalizations.getRecitationText('reciter', appLanguage)),
            subtitle: Text(
              selected.name,
              style: _rowSubtitleStyle(context),
            ),
            childrenPadding: EdgeInsets.zero,
            children: ReciterCatalog.reciters.map((reciter) {
              return RadioListTile<String>(
                value: reciter.id,
                groupValue: selected.id,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(reciterProvider.notifier).select(ReciterCatalog.byId(value));
                  }
                },
                title: Text(reciter.name),
                subtitle: Text(
                  '${reciter.arabicName}  -  ${reciter.bitrate} kbps',
                  style: _rowSubtitleStyle(context),
                ),
                dense: true,
              );
            }).toList(),
          ),
        ),
        Builder(
          builder: (context) {
            final reciter = ref.watch(reciterProvider);
            final downloads = ref.watch(audioDownloadProvider);
            final saved = downloads.completed
                .where((k) => k.startsWith('${reciter.id}:'))
                .length;
            return ListTile(
              leading: const SettingsRowBadge(Icons.download_for_offline_outlined),
              title: _rowTitle(
                context,
                AppLocalizations.getRecitationText('save_recitation_audio', appLanguage),
              ),
              subtitle: Text(
                saved >= AudioOfflinePrompts.totalSurahs
                    ? AppLocalizations.recAllSavedFor(reciter.name, appLanguage)
                    : AppLocalizations.recSavedForReciterShort(
                        saved,
                        AudioOfflinePrompts.totalSurahs,
                        reciter.name,
                        appLanguage,
                      ),
                style: _rowSubtitleStyle(context),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AudioDownloadsScreen(),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class SettingsAppSection extends ConsumerWidget {
  const SettingsAppSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSectionCard(
      title: AppLocalizations.getSettingsText('app_settings_header', appLanguage),
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const SettingsRowBadge(Icons.palette),
            title: _rowTitle(context, AppLocalizations.getSettingsText('theme_title', appLanguage)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(settingsThemeModeName(settings.themeMode, appLanguage)),
                Text(
                  AppLocalizations.getSettingsText('theme_subtitle', appLanguage),
                  style: _rowSubtitleStyle(context),
                ),
              ],
            ),
            childrenPadding: EdgeInsets.zero,
            children: ThemeMode.values.map((mode) {
              final descKey = switch (mode) {
                ThemeMode.system => 'theme_system_desc',
                ThemeMode.light => 'theme_light_desc',
                ThemeMode.dark => 'theme_dark_desc',
              };
              return ListTile(
                leading: Icon(
                  settingsThemeModeIcon(mode),
                  color: settings.themeMode == mode
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                title: Text(settingsThemeModeName(mode, appLanguage)),
                subtitle: Text(
                  AppLocalizations.getSettingsText(descKey, appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
                trailing: Radio<ThemeMode>(
                  value: mode,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateThemeMode(value);
                    }
                  },
                ),
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                onTap: () {
                  ref.read(settingsProvider.notifier).updateThemeMode(mode);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class SettingsRemindersSection extends ConsumerWidget {
  const SettingsRemindersSection({super.key});

  String _formatTime(BuildContext context, int hour, int minute) {
    final dt = DateTime(2000, 1, 1, hour, minute);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(dt),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.weeklyReminderHour,
        minute: settings.weeklyReminderMinute,
      ),
    );
    if (picked == null || !context.mounted) return;
    await ref.read(settingsProvider.notifier).updateWeeklyReminderTime(
          hour: picked.hour,
          minute: picked.minute,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSectionCard(
      title: AppLocalizations.getSettingsText('reminders_header', appLanguage),
      children: [
        SwitchListTile(
          secondary: const SettingsRowBadge(Icons.notifications_outlined),
          title: _rowTitle(context, AppLocalizations.getSettingsText('weekly_reminder_title', appLanguage)),
          subtitle: Text(
            AppLocalizations.getSettingsText('weekly_reminder_subtitle', appLanguage),
            style: _rowSubtitleStyle(context),
          ),
          value: settings.weeklyReminderEnabled,
          onChanged: (enabled) async {
            final granted = await ref
                .read(settingsProvider.notifier)
                .updateWeeklyReminderEnabled(enabled);
            if (!enabled || granted || !context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.getSettingsText(
                    'weekly_reminder_permission_denied',
                    appLanguage,
                  ),
                ),
              ),
            );
          },
        ),
        if (settings.weeklyReminderEnabled)
          ListTile(
            leading: const SettingsRowBadge(Icons.schedule),
            title: _rowTitle(context, AppLocalizations.getSettingsText('weekly_reminder_time_title', appLanguage)),
            subtitle: Text(
              AppLocalizations.getSettingsText('weekly_reminder_time_hint', appLanguage),
              style: _rowSubtitleStyle(context),
            ),
            trailing: DecoratedBox(
              decoration: ShapeDecoration(
                color: colorScheme.tint,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Text(
                  _formatTime(
                    context,
                    settings.weeklyReminderHour,
                    settings.weeklyReminderMinute,
                  ),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onTint,
                      ),
                ),
              ),
            ),
            onTap: () => _pickTime(context, ref, settings),
          ),
      ],
    );
  }
}

/// Brand card at the top of About: logo, app name and version.
class SettingsAboutBrandHeader extends ConsumerWidget {
  const SettingsAboutBrandHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final versionLabel =
        AppLocalizations.getSettingsText('version_title', appLanguage);
    final version = ref.watch(packageInfoProvider).when(
          data: (info) => '${info.version} (${info.buildNumber})',
          loading: () => '…',
          error: (_, __) => '—',
        );
    const logoSize = 60.0;

    return Material(
      color: colorScheme.tint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Image.asset(
              colorScheme.brightness == Brightness.dark
                  ? 'assets/icon/splash_logo_cream.png'
                  : 'assets/icon/splash_logo_green.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              cacheWidth:
                  (logoSize * MediaQuery.devicePixelRatioOf(context)).ceil(),
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Quran Offline',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$versionLabel $version',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsAboutAppSection extends ConsumerWidget {
  const SettingsAboutAppSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;

    return SettingsSectionCard(
      title: AppLocalizations.getSettingsText('about_app_section', appLanguage),
      children: [
        ListTile(
          leading: const SettingsRowBadge(Icons.star_outline),
          title: _rowTitle(context, AppLocalizations.getSettingsText('rate_app_title', appLanguage)),
          subtitle: Text(AppLocalizations.getSettingsText('rate_app_subtitle', appLanguage), style: _rowSubtitleStyle(context)),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: SettingsLinkActions.openRateAppInStore,
        ),
        ListTile(
          leading: const SettingsRowBadge(Icons.share_outlined),
          title: _rowTitle(context, AppLocalizations.getSettingsText('share_app_title', appLanguage)),
          subtitle: Text(AppLocalizations.getSettingsText('share_app_subtitle', appLanguage), style: _rowSubtitleStyle(context)),
          onTap: () => SettingsLinkActions.shareApp(appLanguage),
        ),
      ],
    );
  }
}

class SettingsAboutSupportSection extends ConsumerWidget {
  const SettingsAboutSupportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;

    return SettingsSectionCard(
      title: AppLocalizations.getSettingsText('about_support_section', appLanguage),
      children: [
        ListTile(
          leading: const SettingsRowBadge(Icons.volunteer_activism_outlined),
          title: _rowTitle(context, AppLocalizations.supportSettingsTitle(appLanguage)),
          subtitle: Text(AppLocalizations.supportSettingsSubtitle(appLanguage), style: _rowSubtitleStyle(context)),
          onTap: () => showSupportSheet(context),
        ),
      ],
    );
  }
}

class SettingsAboutLegalSection extends ConsumerWidget {
  const SettingsAboutLegalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;

    return SettingsSectionCard(
      title: AppLocalizations.getSettingsText('about_legal_section', appLanguage),
      children: [
        ListTile(
          leading: const SettingsRowBadge(Icons.privacy_tip),
          title: _rowTitle(context, AppLocalizations.getSettingsText('privacy_title', appLanguage)),
          subtitle: Text(AppLocalizations.getSettingsText('privacy_subtitle', appLanguage), style: _rowSubtitleStyle(context)),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => SettingsLinkActions.openPrivacy(context),
        ),
        ListTile(
          leading: const SettingsRowBadge(Icons.description),
          title: _rowTitle(context, AppLocalizations.getSettingsText('terms_title', appLanguage)),
          subtitle: Text(AppLocalizations.getSettingsText('terms_subtitle', appLanguage), style: _rowSubtitleStyle(context)),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => SettingsLinkActions.openTerms(context),
        ),
        AboutDataSourcesTile(appLanguage: appLanguage),
      ],
    );
  }
}

class SettingsAboutFeedbackSection extends ConsumerWidget {
  const SettingsAboutFeedbackSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(settingsProvider).appLanguage;

    return SettingsSectionCard(
      title: AppLocalizations.getSettingsText('about_feedback_section', appLanguage),
      children: [
        ListTile(
          leading: const SettingsRowBadge(Icons.bug_report),
          title: _rowTitle(
            context,
            AppLocalizations.getSettingsText('report_bug_title', appLanguage),
          ),
          subtitle: Text(
            AppLocalizations.getSettingsText('report_bug_subtitle', appLanguage),
          ),
          onTap: () {
            final lastAyah =
                FeedbackEmailFallback.ayahFromLastRead(ref.read(lastReadProvider));
            showFeedbackForm(
              context,
              type: FeedbackType.bug,
              language: appLanguage,
              contextData: lastAyah == null
                  ? null
                  : FeedbackContext(
                      surahId: lastAyah.surahId,
                      ayahNo: lastAyah.ayahNo,
                    ),
            );
          },
        ),
      ],
    );
  }
}
