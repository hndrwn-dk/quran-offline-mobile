import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Request for an open [MushafPageView] to jump to a page and scroll to an ayah.
class MushafJumpRequest {
  final int pageNo;
  final int surahId;
  final int? ayahNo;
  final int token;

  const MushafJumpRequest({
    required this.pageNo,
    required this.surahId,
    this.ayahNo,
    required this.token,
  });
}

/// True while a [MushafPageView] route is on screen (avoid pushing another copy).
final mushafSessionActiveProvider = StateProvider<bool>((ref) => false);

final mushafJumpRequestProvider =
    StateProvider<MushafJumpRequest?>((ref) => null);

int _jumpToken = 0;

void requestMushafJump(
  WidgetRef ref, {
  required int pageNo,
  required int surahId,
  int? ayahNo,
}) {
  _jumpToken++;
  ref.read(mushafJumpRequestProvider.notifier).state = MushafJumpRequest(
    pageNo: pageNo,
    surahId: surahId,
    ayahNo: ayahNo,
    token: _jumpToken,
  );
}
