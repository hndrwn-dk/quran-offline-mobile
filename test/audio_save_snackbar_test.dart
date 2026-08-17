import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/providers/audio_download_provider.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';

void main() {
  test('failed download stays active so retry can replace it', () {
    const failed = DownloadProgress(done: 3, total: 10, failed: true);
    const running = DownloadProgress(done: 1, total: 10);
    final failedState = AudioDownloadsState(
      active: {downloadKey('r', 3): failed},
    );
    final runningState = AudioDownloadsState(
      active: {downloadKey('r', 3): running},
    );

    expect(failedState.isDownloading('r', 3), isTrue);
    expect(failedState.progressFor('r', 3)?.failed, isTrue);
    expect(runningState.progressFor('r', 3)?.failed, isFalse);
  });

  test('save-failed copy includes surah name in id and en', () {
    expect(
      AppLocalizations.recSaveFailed("Ali 'Imran", 'id'),
      contains("Ali 'Imran"),
    );
    expect(AppLocalizations.getRecitationText('save_retry', 'id'), 'Coba lagi');
    expect(AppLocalizations.getRecitationText('save_retry', 'en'), 'Retry');
  });
}
