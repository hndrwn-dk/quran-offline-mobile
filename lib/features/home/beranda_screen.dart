import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/support_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/responsive.dart';
import 'package:quran_offline/features/home/widgets/home_activity_section.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/home/widgets/home_explore_favorites_section.dart';
import 'package:quran_offline/features/home/widgets/home_hero_card.dart';
import 'package:quran_offline/features/home/widgets/home_notes_section.dart';
import 'package:quran_offline/features/home/widgets/home_quick_actions.dart';
import 'package:quran_offline/features/home/widgets/reading_milestone_card.dart';
import 'package:quran_offline/features/home/widgets/ramadan_promo_banner.dart';
import 'package:quran_offline/features/read/widgets/last_read_card.dart';
import 'package:quran_offline/features/read/widgets/weekly_reflection_card.dart';
import 'package:quran_offline/features/settings/about_screen.dart';
import 'package:quran_offline/features/settings/settings_screen.dart';
import 'package:quran_offline/features/support/support_sheet.dart';

class BerandaScreen extends ConsumerStatefulWidget {
  const BerandaScreen({super.key});

  @override
  ConsumerState<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends ConsumerState<BerandaScreen> {
  bool _ramadanPromoDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(readingCoverageProvider).onHomeVisible();
    });
  }

  Widget _ramadanPromoBanner() {
    if (_ramadanPromoDismissed) return const SizedBox.shrink();
    return RamadanPromoBanner(
      onDismiss: () => setState(() => _ramadanPromoDismissed = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;
    final colorScheme = Theme.of(context).colorScheme;
    final isLargeScreen = Responsive.isLargeScreen(context);

    final phoneBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeHeroCard(),
        _ramadanPromoBanner(),
        const WeeklyReflectionCard(forHome: true),
        const HomeQuickActions(),
        const ReadingMilestoneSlot(),
        const LastReadCard(forHome: true),
        const HomeExploreFavoritesSection(),
        const HomeNotesSection(),
        const HomeActivitySection(),
        const SizedBox(height: 8),
      ],
    );

    final tabletBody = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HomeHeroCard(),
                _ramadanPromoBanner(),
                const WeeklyReflectionCard(forHome: true),
                const HomeQuickActions(),
              ],
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReadingMilestoneSlot(),
                LastReadCard(forHome: true),
                HomeExploreFavoritesSection(),
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
        flexibleSpace: HomeBackdrop.cornerArcFlexibleSpace(colorScheme),
        leadingWidth: 48,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          iconSize: 22,
          tooltip: AppLocalizations.getSettingsText('about_header', appLanguage),
          onPressed: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const AboutScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            color: colorScheme.onSurfaceVariant,
            iconSize: 22,
            tooltip: AppLocalizations.supportTooltip(appLanguage),
            style: IconButton.styleFrom(
              fixedSize: const Size(44, 44),
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => showSupportSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            iconSize: 22,
            tooltip: AppLocalizations.getSettingsText('settings_title', appLanguage),
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const SettingsScreen(showBackButton: true),
                ),
              );
            },
          ),
        ],
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
