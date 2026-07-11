import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/responsive.dart';
import 'package:quran_offline/core/widgets/coachmark/support_coachmark.dart';
import 'package:quran_offline/features/home/widgets/home_activity_section.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/home/widgets/home_hero_card.dart';
import 'package:quran_offline/features/home/widgets/home_notes_section.dart';
import 'package:quran_offline/features/home/widgets/home_quick_actions.dart';
import 'package:quran_offline/features/home/widgets/ramadan_promo_banner.dart';
import 'package:quran_offline/features/read/widgets/last_read_card.dart';
import 'package:quran_offline/features/read/widgets/weekly_reflection_card.dart';
import 'package:quran_offline/features/settings/about_screen.dart';
import 'package:quran_offline/features/settings/settings_link_actions.dart';
import 'package:quran_offline/features/settings/settings_screen.dart';

class BerandaScreen extends ConsumerStatefulWidget {
  const BerandaScreen({super.key});

  @override
  ConsumerState<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends ConsumerState<BerandaScreen> {
  final _supportIconKey = GlobalKey();
  bool _coachmarkScheduled = false;
  bool _ramadanPromoDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowSupportCoachmark());
  }

  Future<void> _maybeShowSupportCoachmark() async {
    if (_coachmarkScheduled || !mounted) return;
    if (ref.read(currentTabProvider) != AppTab.home) return;

    _coachmarkScheduled = true;
    await SupportCoachmark.maybeShow(
      context: context,
      ref: ref,
      supportIconKey: _supportIconKey,
    );
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
        const LastReadCard(forHome: true),
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
            key: _supportIconKey,
            icon: const Icon(Icons.volunteer_activism_outlined),
            iconSize: 22,
            tooltip: AppLocalizations.getSettingsText('support_title', appLanguage),
            onPressed: () => SettingsLinkActions.openDonate(context),
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
