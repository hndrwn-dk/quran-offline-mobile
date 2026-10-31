import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_offline/core/notifications/notification_navigation.dart';
import 'package:quran_offline/core/notifications/notification_navigation_handler.dart';
import 'package:quran_offline/core/providers/last_read_provider.dart';
import 'package:quran_offline/core/providers/reader_provider.dart';
import 'package:quran_offline/core/providers/reading_completion_provider.dart';
import 'package:quran_offline/core/reading/open_next_read.dart';
import 'package:quran_offline/core/providers/reflection_pick_provider.dart';
import 'package:quran_offline/core/providers/resume_hint_provider.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/providers/tab_provider.dart';
import 'package:quran_offline/core/startup/startup_destination.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/utils/system_bottom_inset.dart';
import 'package:quran_offline/core/widgets/floating_nav_bar.dart';
import 'package:quran_offline/core/widgets/home_widget_navigation.dart';
import 'package:quran_offline/core/widgets/home_widget_sync.dart';
import 'package:quran_offline/features/dua/dua_screen.dart';
import 'package:quran_offline/features/home/beranda_screen.dart';
import 'package:quran_offline/features/library/my_library_screen.dart';
import 'package:quran_offline/features/read/read_screen.dart';
import 'package:quran_offline/features/read/widgets/mushaf_page_view.dart';
import 'package:quran_offline/features/reader/open_reader_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final hadNotification = NotificationNavigation.pendingPayload != null;
      registerNotificationNavigationHandler(context, ref);
      final handledWidgetLaunch =
          await HomeWidgetNavigation.register(context, ref);
      if (!mounted) return;
      HomeWidgetSync.updateFromRef(ref);
      if (!hadNotification && !handledWidgetLaunch) {
        await _resumeLastRead();
      }
    });
  }

  Future<void> _resumeLastRead() async {
    await ref.read(lastReadProvider.notifier).loaded;
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final openToLastRead = prefs.getBool('openToLastRead') ?? true;
    if (!mounted) return;

    // An explicit quranoffline:// launch route always wins over auto-resume.
    final hasDeepLink = WidgetsBinding
        .instance.platformDispatcher.defaultRouteName
        .startsWith('quranoffline://');
    final lastRead = ref.read(lastReadProvider);
    final destination = decideStartupDestination(
      openToLastRead: openToLastRead,
      hasLastRead: lastRead != null,
      hasDeepLink: hasDeepLink,
    );
    if (destination != StartupDestination.resume || lastRead == null) return;

    final completion = await ref.read(readingCompletionProvider.future);
    if (!mounted) return;
    if (completion != null) {
      await openNextReadTarget(context, ref, completion);
      return;
    }

    if (lastRead.type == 'page') {
      ref.read(resumeHintProvider.notifier).state =
          ResumeHint.page(pageNo: lastRead.id);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MushafPageView(
            initialPage: lastRead.id,
            targetSurahId: lastRead.surahId,
            targetAyahNo: lastRead.ayahNo,
          ),
        ),
      );
      return;
    }

    ref.read(readerSourceProvider.notifier).state = lastRead.toReaderSource();
    ref.read(targetAyahProvider.notifier).state = lastRead.ayahNo;
    ref.read(targetSurahIdProvider.notifier).state =
        lastRead.type == 'juz' ? lastRead.surahId : null;
    if (lastRead.type == 'surah') {
      ref.read(resumeHintProvider.notifier).state = ResumeHint.surah(
        surahId: lastRead.id,
        ayahNo: lastRead.ayahNo ?? 1,
      );
    }
    await openReaderScreen(context, ref);
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
    final keyboardOpen = imeVisible(MediaQuery.of(context));

    return AudioDownloadNotifications(
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: true,
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
        bottomNavigationBar: keyboardOpen
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GlobalRecitationBar(padForSystemBottomInset: false),
                  FloatingNavBar(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) {
                      if (index != currentIndex) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      }
                      ref.read(currentTabProvider.notifier).state = index;
                    },
                    destinations: [
                      FloatingNavDestination(
                        key: const Key('nav_home'),
                        icon: Icons.foundation_outlined,
                        selectedIcon: Icons.foundation,
                        label: AppLocalizations.getNavMenuText(
                            'home', appLanguage),
                      ),
                      FloatingNavDestination(
                        key: const Key('nav_read'),
                        icon: Icons.auto_stories_outlined,
                        selectedIcon: Icons.auto_stories,
                        label: AppLocalizations.getNavMenuText(
                            'read', appLanguage),
                      ),
                      FloatingNavDestination(
                        key: const Key('nav_search'),
                        icon: Icons.travel_explore_outlined,
                        selectedIcon: Icons.travel_explore,
                        label: AppLocalizations.getNavMenuText(
                          'search',
                          appLanguage,
                        ),
                      ),
                      FloatingNavDestination(
                        key: const Key('nav_explore'),
                        icon: Icons.library_books_outlined,
                        selectedIcon: Icons.library_books,
                        label:
                            AppLocalizations.getNavMenuText('dua', appLanguage),
                      ),
                      FloatingNavDestination(
                        key: const Key('nav_library'),
                        icon: Icons.collections_bookmark_outlined,
                        selectedIcon: Icons.collections_bookmark,
                        label: AppLocalizations.getNavMenuText(
                          'library',
                          appLanguage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
