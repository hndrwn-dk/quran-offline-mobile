import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

final readModeProvider = StateProvider<ReadMode>((ref) => ReadMode.surah);

enum ReadMode {
  surah,
  juz,
  pages,
}

