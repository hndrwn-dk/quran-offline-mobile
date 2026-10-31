import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/review/review_ask_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  test('requests a review once and persists the flag', () async {
    final store = await prefs();
    var requests = 0;
    final controller = ReviewAskController(
      prefs: store,
      requestReview: () async => requests++,
      delay: Duration.zero,
    );

    expect(
      await controller.onCompletion(isAudioPlaying: () => false),
      isTrue,
    );
    expect(requests, 1);
    expect(store.getBool(ReviewAskController.flagKey), isTrue);

    expect(
      await controller.onCompletion(isAudioPlaying: () => false),
      isFalse,
    );
    expect(requests, 1);
  });

  test('never requests again when the flag is already set', () async {
    SharedPreferences.setMockInitialValues({
      ReviewAskController.flagKey: true,
    });
    final store = await SharedPreferences.getInstance();
    var requests = 0;
    final controller = ReviewAskController(
      prefs: store,
      requestReview: () async => requests++,
      delay: Duration.zero,
    );

    expect(
      await controller.onCompletion(isAudioPlaying: () => false),
      isFalse,
    );
    expect(requests, 0);
  });

  test('skips while audio is playing and defers to the next completion',
      () async {
    final store = await prefs();
    var requests = 0;
    final controller = ReviewAskController(
      prefs: store,
      requestReview: () async => requests++,
      delay: Duration.zero,
    );

    expect(
      await controller.onCompletion(isAudioPlaying: () => true),
      isFalse,
    );
    expect(requests, 0);
    expect(store.getBool(ReviewAskController.flagKey), isNull);

    expect(
      await controller.onCompletion(isAudioPlaying: () => false),
      isTrue,
    );
    expect(requests, 1);
  });

  test('aborts when audio starts during the delay', () async {
    final store = await prefs();
    var requests = 0;
    var playing = false;
    final controller = ReviewAskController(
      prefs: store,
      requestReview: () async => requests++,
      delay: const Duration(milliseconds: 30),
    );

    final pending = controller.onCompletion(isAudioPlaying: () => playing);
    playing = true;

    expect(await pending, isFalse);
    expect(requests, 0);
    expect(store.getBool(ReviewAskController.flagKey), isNull);
  });

  test('fails silently when the review request throws', () async {
    final store = await prefs();
    var requests = 0;
    final controller = ReviewAskController(
      prefs: store,
      requestReview: () async {
        requests++;
        throw Exception('no Play Services');
      },
      delay: Duration.zero,
    );

    expect(
      await controller.onCompletion(isAudioPlaying: () => false),
      isTrue,
    );
    expect(requests, 1);
    expect(store.getBool(ReviewAskController.flagKey), isTrue);
  });
}
