import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/home_widget_navigation.dart';
import 'package:quran_offline/core/widgets/home_widget_sync.dart';
import 'package:quran_offline/features/dua/dua_screen.dart';
import 'package:quran_offline/features/home/beranda_screen.dart';
import 'package:quran_offline/features/library/my_library_screen.dart';
import 'package:quran_offline/features/read/read_screen.dart';
import 'package:quran_offline/features/search/search_screen.dart';
import 'package:quran_offline/features/audio/global_recitation_bar.dart';
import 'package:quran_offline/features/audio/audio_download_notifications.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      HomeWidgetNavigation.register(context, ref);
      HomeWidgetSync.updateFromRef(ref);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HomeWidgetNavigation.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      HomeWidgetSync.updateFromRef(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(lastReadProvider, (_, __) {
      HomeWidgetSync.updateFromRef(ref);
    });
    ref.listen(settingsProvider, (_, __) {
      HomeWidgetSync.updateFromRef(ref);
    });
    ref.listen(reflectionPickProvider, (_, __) {
      HomeWidgetSync.updateFromRef(ref);
    });

    final currentIndex = ref.watch(currentTabProvider);
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;

    return AudioDownloadNotifications(
      child: Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          BerandaScreen(),
          ReadScreen(),
          SearchScreen(),
          DuaScreen(),
          MyLibraryScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GlobalRecitationBar(padForSystemBottomInset: false),
            NavigationBar(
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                ref.read(currentTabProvider.notifier).state = index;
              },
              destinations: [
                NavigationDestination(
                  key: const Key('nav_home'),
                  icon: const Icon(Icons.foundation_outlined),
                  selectedIcon: const Icon(Icons.foundation),
                  label: AppLocalizations.getNavMenuText('home', appLanguage),
                ),
                NavigationDestination(
                  key: const Key('nav_read'),
                  icon: const Icon(Icons.auto_stories_outlined),
                  selectedIcon: const Icon(Icons.auto_stories),
                  label: AppLocalizations.getNavMenuText('read', appLanguage),
                ),
                NavigationDestination(
                  key: const Key('nav_search'),
                  icon: const Icon(Icons.travel_explore_outlined),
                  selectedIcon: const Icon(Icons.travel_explore),
                  label: AppLocalizations.getNavMenuText('search', appLanguage),
                ),
                NavigationDestination(
                  key: const Key('nav_explore'),
                  icon: const Icon(Icons.library_books_outlined),
                  selectedIcon: const Icon(Icons.library_books),
                  label: AppLocalizations.getNavMenuText('dua', appLanguage),
                ),
                NavigationDestination(
                  key: const Key('nav_library'),
                  icon: const Icon(Icons.collections_bookmark_outlined),
                  selectedIcon: const Icon(Icons.collections_bookmark),
                  label: AppLocalizations.getNavMenuText('library', appLanguage),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
