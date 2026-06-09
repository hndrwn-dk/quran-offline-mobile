import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_offline/core/models/juz_amma_hafalan.dart';

void main() {
  test('juz amma units catalog loads with 41 units for surah 78-114', () {
    final raw = File('assets/hafalan/juz_amma_units.json').readAsStringSync();
    final program = JuzAmmaProgram.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    expect(program.juz, 30);
    expect(program.units.length, 41);
    expect(program.units.first.surah, 114);
    expect(program.units.last.surah, 78);
  });

  test('resolveHafalanDay uses Friday for murojaah', () {
    final program = JuzAmmaProgram(
      version: 1,
      juz: 30,
      tahsinDays: 5,
      units: [
        const JuzAmmaUnit(sort: 1, surah: 114, from: 1, to: 6),
        const JuzAmmaUnit(sort: 2, surah: 113, from: 1, to: 5),
      ],
    );
    // 2026-06-01 is Monday
    final monday = DateTime(2026, 6, 1);
    final taskMon = resolveHafalanDay(
      now: monday,
      programStart: monday,
      program: program,
    );
    expect(taskMon.kind, HafalanDayKind.newMemorization);
    expect(taskMon.unit?.surah, 114);

    // 2026-06-05 is Friday
    final friday = DateTime(2026, 6, 5);
    final taskFri = resolveHafalanDay(
      now: friday,
      programStart: monday,
      program: program,
    );
    expect(taskFri.kind, HafalanDayKind.murojaah);
  });

  test('isJuzAmmaSurah covers juz 30 range only', () {
    expect(isJuzAmmaSurah(77), isFalse);
    expect(isJuzAmmaSurah(78), isTrue);
    expect(isJuzAmmaSurah(114), isTrue);
    expect(isJuzAmmaSurah(1), isFalse);
  });

  test('resolveFridaySetoranQueue lists units from Sat-Thu window', () {
    final program = JuzAmmaProgram(
      version: 1,
      juz: 30,
      tahsinDays: 5,
      units: [
        const JuzAmmaUnit(sort: 1, surah: 114, from: 1, to: 6),
        const JuzAmmaUnit(sort: 2, surah: 113, from: 1, to: 5),
        const JuzAmmaUnit(sort: 3, surah: 112, from: 1, to: 4),
        const JuzAmmaUnit(sort: 4, surah: 111, from: 1, to: 5),
        const JuzAmmaUnit(sort: 5, surah: 110, from: 1, to: 3),
        const JuzAmmaUnit(sort: 6, surah: 109, from: 1, to: 6),
      ],
    );
    // Program starts Monday 2026-06-01; Friday 2026-06-05 setor Senin–Kamis (4 unit)
    final friday1 = resolveFridaySetoranQueue(
      now: DateTime(2026, 6, 5),
      programStart: DateTime(2026, 6, 1),
      program: program,
    );
    expect(friday1.length, 4);
    expect(friday1.first.surah, 114);
    expect(friday1.last.surah, 111);

    // Friday 2026-06-12 setor Sab 6 – Kamis 11 (unit 4–5 in sample program)
    final friday2 = resolveFridaySetoranQueue(
      now: DateTime(2026, 6, 12),
      programStart: DateTime(2026, 6, 1),
      program: program,
    );
    expect(friday2.length, 2);
    expect(friday2.first.surah, 110);
    expect(friday2.last.surah, 109);
  });

  test('partial program fallback lists units with memorized ayahs', () {
    final program = JuzAmmaProgram(
      version: 1,
      juz: 30,
      tahsinDays: 5,
      units: [
        const JuzAmmaUnit(sort: 1, surah: 114, from: 1, to: 6),
        const JuzAmmaUnit(sort: 2, surah: 113, from: 1, to: 5),
        const JuzAmmaUnit(sort: 3, surah: 112, from: 1, to: 4),
      ],
    );
    final units = resolveFridaySetoranQueueFromPartialProgram(
      program: program,
      memorizedKeys: {'114:1', '114:4', '112:1'},
    );
    expect(units.length, 2);
    expect(units.map((u) => u.surah).toList(), [114, 112]);
  });

  test('all memorized fallback groups ayahs per surah', () {
    final units = resolveFridaySetoranQueueFromAllMemorized(
      memorizedKeys: {'114:2', '114:6', '113:1'},
    );
    expect(units.length, 2);
    expect(units.first.surah, 114);
    expect(units.first.from, 2);
    expect(units.first.to, 6);
  });
}
