import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/widgets/home_widget_payload.dart';
import 'package:quran_offline/core/widgets/home_widget_progress.dart';

void main() {
  group('BerandaWidgetPayload', () {
    test('round-trips through JSON encode/decode', () {
      const original = BerandaWidgetPayload(
        tagline: 'Baca, renungkan, lanjutkan tilawah',
        reflectionLabel: 'Renungan mingguan',
        reflectionTitle: 'Ketika ujian datang',
        reflectionRef: 'Al-Baqarah 2:155-157',
        reflectionBadge: 'Kesabaran',
        reflectionContext: 'Ujian datang untuk menguji iman.',
        continueLabel: 'Lanjutkan baca',
        surahName: 'Al-Kahf',
        ayahNo: 45,
        surahPercent: 41,
        juzLabel: 'Juz 15',
        juzPercent: 58,
        surahCurrent: 45,
        surahTotal: 110,
        juzCurrent: 142,
        juzTotal: 246,
        readDeepLink: 'quranoffline://read?surah=18&ayah=45',
        reflectionDeepLink: 'quranoffline://reflection',
        hasContinue: true,
      );

      final decoded = BerandaWidgetPayload.decode(original.encode());
      expect(decoded.tagline, original.tagline);
      expect(decoded.reflectionTitle, original.reflectionTitle);
      expect(decoded.surahPercent, 41);
      expect(decoded.juzPercent, 58);
      expect(decoded.hasContinue, isTrue);
    });
  });

  group('widgetProgressPercent', () {
    test('clamps and rounds', () {
      expect(widgetProgressPercent(45, 110), 41);
      expect(widgetProgressPercent(0, 110), 0);
      expect(widgetProgressPercent(110, 110), 100);
      expect(widgetProgressPercent(1, 0), 0);
    });
  });
}
