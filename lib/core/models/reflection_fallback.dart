import 'package:quran_offline/core/models/dua_entry.dart';
import 'package:quran_offline/core/models/reflection_lens.dart';

const kReflectionFallbackEntries = <ReflectionLensEntry>[
  ReflectionLensEntry(
    id: 'fallback_fatihah',
    sort: 10,
    priority: 0,
    badgeKey: 'weekly',
    title: LocalizedText(
      id: 'Pembuka setiap shalat',
      en: 'The opening of every prayer',
      zh: '每番礼拜的开端',
      ja: '礼拝の開端',
    ),
    summary: LocalizedText(
      id: 'Al-Fatihah adalah doa petunjuk yang kita baca setiap rakaat.',
      en: 'Al-Fatihah is the prayer for guidance we recite in every rakah.',
      zh: '开端章是每一拜都诵读的求引导之祷。',
      ja: '開端章は、各ラカアで唱える導きの祈りである。',
    ),
    reflection: LocalizedText(
      id: 'Baca pelan; mintalah petunjuk ke jalan yang lurus.',
      en: 'Read slowly; ask for guidance on the straight path.',
      zh: '慢慢读；求引导于正道。',
      ja: 'ゆっくり読み、まっすぐな道への導きを願う。',
    ),
    ayahRefs: [DuaAyahRef(surah: 1, from: 1, to: 7)],
  ),
  ReflectionLensEntry(
    id: 'fallback_ikhlas',
    sort: 20,
    priority: 0,
    badgeKey: 'weekly',
    title: LocalizedText(
      id: 'Allah Maha Esa',
      en: 'Allah is One',
      zh: '真主是独一的',
      ja: 'アッラーは唯一である',
    ),
    summary: LocalizedText(
      id: 'Al-Ikhlas menyatakan tauhid dengan singkat dan jelas.',
      en: 'Al-Ikhlas states tawhid in a few clear lines.',
      zh: '忠诚章以简短明白的经文阐明认主独一。',
      ja: '忠誠章は、タウヒードを短く明確に述べる。',
    ),
    reflection: LocalizedText(
      id: 'Ucapkan dengan yakin: Allah tidak beranak dan tidak diperanakkan.',
      en: 'Say with certainty: Allah neither begets nor is born.',
      zh: '确信地诵读：真主不生也不被生。',
      ja: '確信をもって唱える。アッラーは生まず、生まれもしない。',
    ),
    ayahRefs: [DuaAyahRef(surah: 112, from: 1, to: 4)],
  ),
  ReflectionLensEntry(
    id: 'fallback_asr',
    sort: 30,
    priority: 0,
    badgeKey: 'weekly',
    title: LocalizedText(
      id: 'Demi masa',
      en: 'By time',
      zh: '以时光发誓',
      ja: '時にかけて',
    ),
    summary: LocalizedText(
      id: 'Al-Asr mengingatkan bahwa manusia merugi kecuali yang beriman dan beramal.',
      en: 'Al-Asr reminds us that people are in loss except those who believe and do good.',
      zh: '时光章提醒：人确是在亏折中，除非信道而且行善。',
      ja: '午後章は、人は損失の中にあり、信仰し善を行う者を除くと教える。',
    ),
    reflection: LocalizedText(
      id: 'Luangkan waktu untuk iman, amal, dan nasihat yang benar.',
      en: 'Make time for faith, good work, and truthful counsel.',
      zh: '为信仰、善功和互相劝勉留出时间。',
      ja: '信仰、善行、そして誠実な忠告のための時間を取る。',
    ),
    ayahRefs: [DuaAyahRef(surah: 103, from: 1, to: 3)],
  ),
];
