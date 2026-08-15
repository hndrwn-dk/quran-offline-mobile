import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/audio/recitation_primary_action.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

void main() {
  group('recitationPrimaryAction', () {
    test('playing session offers pause, not stop', () {
      final action = recitationPrimaryAction(isPlaying: true);
      expect(action, RecitationPrimaryAction.pause);
      expect(action.tooltipKey, 'pause');
    });

    test('paused session offers resume', () {
      final action = recitationPrimaryAction(isPlaying: false);
      expect(action, RecitationPrimaryAction.resume);
      expect(action.tooltipKey, 'play');
    });
  });

  group('pause tooltip', () {
    test('is translated for every supported language', () {
      expect(AppLocalizations.getActionTooltip('pause', 'id'), 'Jeda');
      expect(AppLocalizations.getActionTooltip('pause', 'en'), 'Pause');
      expect(AppLocalizations.getActionTooltip('pause', 'zh'), '暂停');
      expect(AppLocalizations.getActionTooltip('pause', 'ja'), '一時停止');
    });

    test('falls back to English for unknown language', () {
      expect(AppLocalizations.getActionTooltip('pause', 'fr'), 'Pause');
    });

    test('stop tooltip stays available for the close button', () {
      expect(AppLocalizations.getActionTooltip('stop_recitation', 'id'),
          'Hentikan tilawah');
    });
  });
}
