import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/responsive.dart';
import 'package:quran_offline/features/home/widgets/home_activity_section.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/home/widgets/home_hero_card.dart';
import 'package:quran_offline/features/home/widgets/home_notes_section.dart';
import 'package:quran_offline/features/home/widgets/home_quick_actions.dart';
import 'package:quran_offline/features/read/widgets/last_read_card.dart';
import 'package:quran_offline/features/read/widgets/weekly_reflection_card.dart';
import 'package:quran_offline/features/settings/settings_screen.dart';

class BerandaScreen extends ConsumerWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final isLargeScreen = Responsive.isLargeScreen(context);

    final phoneBody = const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeHeroCard(),
        WeeklyReflectionCard(forHome: true),
        HomeQuickActions(),
        LastReadCard(forHome: true),
        HomeNotesSection(),
        HomeActivitySection(),
        SizedBox(height: 8),
      ],
    );

    final tabletBody = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HomeHeroCard(),
                WeeklyReflectionCard(forHome: true),
                HomeQuickActions(),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LastReadCard(forHome: true),
                HomeNotesSection(),
                HomeActivitySection(),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 48,
        centerTitle: false,
        backgroundColor: HomeBackdrop.topTint(colorScheme),
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: HomeBackdrop.overlayStyle(colorScheme),
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.tune_outlined),
          iconSize: 22,
          tooltip: AppLocalizations.getMenuText('settings', appLanguage),
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const SettingsScreen(showBackButton: true),
              ),
            );
          },
        ),
      ),
      body: HomeBackdrop(
        child: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            child: isLargeScreen ? tabletBody : phoneBody,
          ),
        ),
      ),
    );
  }
}
