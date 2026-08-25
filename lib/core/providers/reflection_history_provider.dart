import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/reflection_history_store.dart';

final reflectionInstallSaltProvider = FutureProvider<String>((ref) async {
  return ReflectionHistoryStore().readOrCreateInstallSalt();
});
