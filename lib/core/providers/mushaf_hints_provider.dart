import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/utils/mushaf_hints_prefs.dart';

final mushafGestureHintVisibleProvider = FutureProvider<bool>((ref) async {
  return !(await MushafHintsPrefs.isGestureHintDismissed());
});

final mushafAudioHintDismissedProvider =
    FutureProvider.family<bool, String>((ref, reciterId) async {
  return MushafHintsPrefs.isAudioPromptDismissed(reciterId);
});

Future<void> dismissMushafGestureHint(WidgetRef ref) async {
  await MushafHintsPrefs.dismissGestureHint();
  ref.invalidate(mushafGestureHintVisibleProvider);
}

Future<void> dismissMushafAudioHint(WidgetRef ref, String reciterId) async {
  await MushafHintsPrefs.dismissAudioPrompt(reciterId);
  ref.invalidate(mushafAudioHintDismissedProvider(reciterId));
}
