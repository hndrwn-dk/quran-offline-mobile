import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom navigation tab indices (5 destinations).
abstract final class AppTab {
  static const int home = 0;
  static const int read = 1;
  static const int search = 2;
  static const int explore = 3;
  static const int library = 4;
}

final currentTabProvider = StateProvider<int>((ref) => AppTab.home);

/// When set, [MyLibraryScreen] switches to this sub-tab then clears the value.
/// 0 = bookmarks, 1 = notes, 2 = highlights.
final librarySubTabProvider = StateProvider<int?>((ref) => null);

final readModeProvider = StateProvider<ReadMode>((ref) => ReadMode.surah);

enum ReadMode {
  surah,
  juz,
  pages,
}

