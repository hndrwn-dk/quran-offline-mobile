import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/features/dua/dua_screen.dart';
import 'package:quran_offline/features/library/my_library_screen.dart';
import 'package:quran_offline/features/read/read_screen.dart';
import 'package:quran_offline/features/search/search_screen.dart';
import 'package:quran_offline/features/settings/settings_screen.dart';
import 'package:quran_offline/features/audio/global_recitation_bar.dart';
import 'package:quran_offline/features/audio/audio_download_notifications.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabProvider);
    final settings = ref.watch(settingsProvider);
    final appLanguage = settings.appLanguage;

    return AudioDownloadNotifications(
      child: Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          ReadScreen(),
          SearchScreen(),
          DuaScreen(),
          MyLibraryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GlobalRecitationBar(padForSystemBottomInset: false),
          NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(currentTabProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: AppLocalizations.getMenuText('read', appLanguage),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: AppLocalizations.getMenuText('search', appLanguage),
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories),
            label: AppLocalizations.getMenuText('dua', appLanguage),
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_books_outlined),
            selectedIcon: const Icon(Icons.library_books),
            label: AppLocalizations.getMenuText('library', appLanguage),
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune),
            label: AppLocalizations.getMenuText('settings', appLanguage),
          ),
        ],
          ),
        ],
      ),
    ),
    );
  }
}

