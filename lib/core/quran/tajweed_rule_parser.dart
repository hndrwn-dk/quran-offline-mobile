enum TajweedClass {
  madda_normal,
  madda_permissible,
  madda_necessary,
  madda_obligatory,
  ham_wasl,
  laam_shamsiyah,
  ghunnah,
  ikhfa,
  idgham,
  idgham_ghunnah,
  idgham_shafawi,
  idgham_wo_ghunnah,
  iqlab,
  qalqalah,
  qalaqah,
  silent,
  slnt,
  unknown,
}

class TajweedSpan {
  const TajweedSpan({
    required this.arabicText,
    required this.rule,
    required this.spanIndex,
  });

  final String arabicText;
  final TajweedClass rule;
  final int spanIndex;

  bool get isMad =>
      rule == TajweedClass.madda_normal ||
      rule == TajweedClass.madda_permissible ||
      rule == TajweedClass.madda_necessary ||
      rule == TajweedClass.madda_obligatory;

  String labelId(String language) {
    final id = switch (rule) {
      TajweedClass.madda_normal => 'Mad Tabi\'i',
      TajweedClass.madda_permissible => 'Mad Jaiz Munfasil',
      TajweedClass.madda_necessary => 'Mad Lazim',
      TajweedClass.madda_obligatory => 'Mad Wajib',
      TajweedClass.ham_wasl => 'Hamzah Washal',
      TajweedClass.laam_shamsiyah => 'Lam Syamsiyah',
      TajweedClass.ghunnah => 'Ghunnah',
      TajweedClass.ikhfa => 'Ikhfa',
      TajweedClass.idgham => 'Idgham',
      TajweedClass.idgham_ghunnah => 'Idgham bighunnah',
      TajweedClass.idgham_shafawi => 'Idgham syafawi',
      TajweedClass.idgham_wo_ghunnah => 'Idgham tanpa ghunnah',
      TajweedClass.iqlab => 'Iqlab',
      TajweedClass.qalqalah => 'Qalqalah',
      TajweedClass.qalaqah => 'Qalqalah',
      TajweedClass.silent => 'Huruf diam',
      TajweedClass.slnt => 'Huruf diam',
      TajweedClass.unknown => 'Tajwid lain',
    };
    if (language == 'id') return id;
    return switch (rule) {
      TajweedClass.madda_normal => 'Madd tabi\'i',
      TajweedClass.madda_permissible => 'Madd jaiz munfasil',
      TajweedClass.madda_necessary => 'Madd lazim',
      TajweedClass.madda_obligatory => 'Madd wajib',
      TajweedClass.ham_wasl => 'Hamzah wasl',
      TajweedClass.laam_shamsiyah => 'Lam shamsiyah',
      TajweedClass.ghunnah => 'Ghunnah',
      TajweedClass.ikhfa => 'Ikhfa',
      TajweedClass.idgham => 'Idgham',
      TajweedClass.idgham_ghunnah => 'Idgham with ghunnah',
      TajweedClass.idgham_shafawi => 'Idgham shafawi',
      TajweedClass.idgham_wo_ghunnah => 'Idgham without ghunnah',
      TajweedClass.iqlab => 'Iqlab',
      TajweedClass.qalqalah => 'Qalqalah',
      TajweedClass.qalaqah => 'Qalqalah',
      TajweedClass.silent => 'Silent letter',
      TajweedClass.slnt => 'Silent letter',
      TajweedClass.unknown => 'Other tajweed',
    };
  }

  String tipId(String language) {
    if (language == 'id') {
      return switch (rule) {
        TajweedClass.madda_normal =>
          'Panjangkan 2 harakat (sekitar setengah detik)',
        TajweedClass.madda_permissible =>
          'Boleh 2, 4, atau 5 harakat — pilih satu dan konsisten',
        TajweedClass.madda_necessary =>
          'Wajib 6 harakat — ini yang paling panjang',
        TajweedClass.madda_obligatory =>
          'Wajib 4–5 harakat sesuai bacaan',
        TajweedClass.ham_wasl =>
          'Sambungkan dengan kata sebelumnya — tanpa jeda glottal',
        TajweedClass.laam_shamsiyah =>
          'Lam ال tidak dibaca — langsung ke huruf berikutnya',
        TajweedClass.ghunnah =>
          'Dengungkan lewat hidung selama kira-kira 2 harakat',
        TajweedClass.ikhfa => 'Samarkan bunyi dengan dengung ringan',
        TajweedClass.idgham => 'Gabungkan bunyi ke huruf berikutnya',
        TajweedClass.idgham_ghunnah =>
          'Gabungkan dengan dengung 2 harakat',
        TajweedClass.idgham_shafawi =>
          'Gabungkan mim sukun ke mim berikutnya',
        TajweedClass.idgham_wo_ghunnah =>
          'Gabungkan tanpa dengung',
        TajweedClass.iqlab => 'Ubah nun sukun menjadi mim dengan dengung',
        TajweedClass.qalqalah => 'Bunyikan getaran pada huruf qalqalah',
        TajweedClass.qalaqah => 'Bunyikan getaran pada huruf qalqalah',
        TajweedClass.silent => 'Huruf ini tidak dibaca',
        TajweedClass.slnt => 'Huruf ini tidak dibaca',
        TajweedClass.unknown => '',
      };
    }
    return switch (rule) {
      TajweedClass.madda_normal => 'Hold for 2 counts',
      TajweedClass.madda_permissible => 'Hold 2, 4, or 5 counts consistently',
      TajweedClass.madda_necessary => 'Hold for 6 counts',
      TajweedClass.madda_obligatory => 'Hold 4–5 counts as required',
      TajweedClass.ham_wasl => 'Connect smoothly without a glottal stop',
      TajweedClass.laam_shamsiyah =>
        'Do not pronounce lam — go straight to the next letter',
      TajweedClass.ghunnah => 'Nasalize for about 2 counts',
      TajweedClass.ikhfa => 'Conceal the sound with light nasalization',
      TajweedClass.idgham => 'Merge into the following letter',
      TajweedClass.idgham_ghunnah => 'Merge with 2-count ghunnah',
      TajweedClass.idgham_shafawi => 'Merge mim sukun into the next mim',
      TajweedClass.idgham_wo_ghunnah => 'Merge without ghunnah',
      TajweedClass.iqlab => 'Convert nun sukun to mim with ghunnah',
      TajweedClass.qalqalah => 'Echo the qalqalah letter',
      TajweedClass.qalaqah => 'Echo the qalqalah letter',
      TajweedClass.silent => 'This letter is not pronounced',
      TajweedClass.slnt => 'This letter is not pronounced',
      TajweedClass.unknown => '',
    };
  }
}

class TajweedRuleMap {
  TajweedRuleMap(this.spans);

  final List<TajweedSpan> spans;

  List<TajweedSpan> get madSpans => spans.where((s) => s.isMad).toList();
  List<TajweedSpan> get laamSpans =>
      spans.where((s) => s.rule == TajweedClass.laam_shamsiyah).toList();
  List<TajweedSpan> get ghunnahSpans =>
      spans.where((s) => s.rule == TajweedClass.ghunnah).toList();

  bool get hasAnyRule => spans.isNotEmpty;
  bool get hasMadLazim =>
      spans.any((s) => s.rule == TajweedClass.madda_necessary);

  /// Distinct rule labels for pre-check hints (max [limit]).
  List<TajweedSpan> hintSpans({int limit = 4}) {
    final seen = <TajweedClass>{};
    final out = <TajweedSpan>[];
    for (final span in spans) {
      if (span.rule == TajweedClass.unknown || span.rule == TajweedClass.ham_wasl) {
        continue;
      }
      if (seen.add(span.rule)) {
        out.add(span);
        if (out.length >= limit) break;
      }
    }
    return out;
  }
}

class TajweedRuleParser {
  static final RegExp _endSpanRegex = RegExp(
    r'<span[^>]*class=end[^>]*>.*?</span>',
    dotAll: true,
  );

  static final RegExp _tagRegex = RegExp(
    r'<tajweed\s+class=([a-z_]+)>(.*?)</tajweed>',
    dotAll: true,
  );

  /// Parse string from DB column `tajweed` (= field `tj` in JSON).
  static TajweedRuleMap parse(String? tajweedHtml) {
    if (tajweedHtml == null || tajweedHtml.trim().isEmpty) {
      return TajweedRuleMap(const []);
    }

    final stripped = tajweedHtml.replaceAll(_endSpanRegex, '');
    final spans = <TajweedSpan>[];
    var spanIndex = 0;

    for (final match in _tagRegex.allMatches(stripped)) {
      final className = match.group(1) ?? '';
      final arabicText = match.group(2) ?? '';
      final rule = TajweedClass.values.firstWhere(
        (c) => c.name == className,
        orElse: () => TajweedClass.unknown,
      );

      if (rule != TajweedClass.unknown && arabicText.isNotEmpty) {
        spans.add(TajweedSpan(
          arabicText: arabicText,
          rule: rule,
          spanIndex: spanIndex++,
        ));
      }
    }

    return TajweedRuleMap(spans);
  }
}
