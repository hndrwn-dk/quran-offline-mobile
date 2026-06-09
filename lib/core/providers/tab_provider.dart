import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom navigation tab indices.
abstract final class AppTab {
  static const int read = 0;
  static const int search = 1;
  static const int dua = 2;
  static const int library = 3;
  static const int settings = 4;
}

final currentTabProvider = StateProvider<int>((ref) => AppTab.read);

final readModeProvider = StateProvider<ReadMode>((ref) => ReadMode.surah);

enum ReadMode {
  surah,
  juz,
  pages,
}

