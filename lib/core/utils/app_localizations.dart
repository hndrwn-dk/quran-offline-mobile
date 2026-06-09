/// Utility class for app UI localization
/// Uses the translation language setting to localize menu items and UI text
class AppLocalizations {
  /// Get localized text for menu items based on language code
  static String getMenuText(String key, String language) {
    return switch (key) {
      'read' => _getRead(language),
      'search' => _getSearch(language),
      'bookmarks' => _getBookmarks(language),
      'settings' => _getSettings(language),
      'surah' => _getSurah(language),
      'juz' => _getJuz(language),
      'mushaf' => _getMushaf(language),
      'page' => _getPage(language),
      'notes' => _getNotes(language),
      'highlights' => _getHighlights(language),
      'library' => _getLibrary(language),
      'dua' => _getDua(language),
      'hafalan' => _getHafalan(language),
      _ => key,
    };
  }

  /// Shorter labels for the bottom navigation bar (avoids two-line wrapping).
  static String getNavMenuText(String key, String language) {
    return switch (key) {
      'library' => _getLibraryNav(language),
      'settings' => _getSettingsNav(language),
      'hafalan' => _getHafalanNav(language),
      _ => getMenuText(key, language),
    };
  }

  static String getDuaCategoryLabel(String category, String language) {
    return switch (category) {
      'daily' => switch (language) {
          'id' => 'Doa harian',
          'zh' => '日常祈祷',
          'ja' => '日々の祈り',
          _ => 'Daily duas',
        },
      'prophet' => switch (language) {
          'id' => 'Doa para nabi',
          'zh' => '众先知祈祷',
          'ja' => '預言者の祈り',
          _ => 'Prophets\' duas',
        },
      'science' => switch (language) {
          'id' => 'Sains',
          'zh' => '科学',
          'ja' => '科学',
          _ => 'Science',
        },
      'asma' => switch (language) {
          'id' => 'Asmaul Husna',
          'zh' => '真主美名',
          'ja' => 'アッラーの美名',
          _ => 'Names of Allah',
        },
      'life_theme' => switch (language) {
          'id' => 'Tema hidup',
          'zh' => '生活主题',
          'ja' => '生活のテーマ',
          _ => 'Life themes',
        },
      _ => category,
    };
  }

  static String getScienceCategoryLabel(String category, String language) {
    return switch (category) {
      'cosmos' => switch (language) {
          'id' => 'Alam semesta',
          'zh' => '宇宙',
          'ja' => '宇宙',
          _ => 'The cosmos',
        },
      'biology' => switch (language) {
          'id' => 'Biologi',
          'zh' => '生物学',
          'ja' => '生物学',
          _ => 'Biology',
        },
      'earth' => switch (language) {
          'id' => 'Bumi & lingkungan',
          'zh' => '地球与环境',
          'ja' => '地球と環境',
          _ => 'Earth & environment',
        },
      'physics' => switch (language) {
          'id' => 'Fisika & materi',
          'zh' => '物理与物质',
          'ja' => '物理学と物質',
          _ => 'Physics & matter',
        },
      _ => category,
    };
  }

  static String getScienceTopicCount(int count, String language) {
    return switch (language) {
      'id' => '$count topik',
      'zh' => '$count 个主题',
      'ja' => 'テーマ $count 件',
      _ => '$count topics',
    };
  }

  static String getScienceNoteHeading(String language) {
    return switch (language) {
      'id' => 'Catatan ilmiah',
      'en' => 'Science note',
      'zh' => '科学说明',
      'ja' => '科学的注記',
      _ => 'Science note',
    };
  }

  static String getScienceLoadError(String language) {
    return switch (language) {
      'id' =>
        'Katalog sains tidak dapat dimuat. Tutup aplikasi sepenuhnya lalu buka lagi (hot reload tidak memuat asset baru).',
      'en' =>
        'Could not load the science catalog. Fully restart the app (hot reload does not bundle new assets).',
      'zh' => '无法加载科学目录。请完全关闭后重新打开应用（热重载不会加载新资源）。',
      'ja' => '科学の目録を読み込めませんでした。アプリを完全に終了して再起動してください。',
      _ => 'Could not load the science catalog. Fully restart the app.',
    };
  }

  static String getReflectionCardTitle(String pickSource, String language) {
    return switch (pickSource) {
      'weekly' => switch (language) {
          'id' => 'Renungan minggu ini',
          'zh' => '本周思考',
          'ja' => '今週の黙想',
          _ => 'Reflection this week',
        },
      _ => switch (language) {
          'id' => 'Renungan hari ini',
          'zh' => '今日思考',
          'ja' => '今日の黙想',
          _ => 'Reflection today',
        },
    };
  }

  static String getReflectionBadge(String badgeKey, String language) {
    return switch (badgeKey) {
      'friday' => switch (language) {
          'id' => 'Jumat',
          'zh' => '主麻',
          'ja' => '金曜',
          _ => 'Friday',
        },
      'ramadan' => switch (language) {
          'id' => 'Ramadan',
          'zh' => '莱麦丹',
          'ja' => 'ラマダーン',
          _ => 'Ramadan',
        },
      'hijrah' => switch (language) {
          'id' => 'Awal Hijriah',
          'zh' => '伊历新年',
          'ja' => 'ヒジュラ暦',
          _ => 'Hijri new year',
        },
      'morning' => switch (language) {
          'id' => 'Pagi',
          'zh' => '早晨',
          'ja' => '朝',
          _ => 'Morning',
        },
      'evening' => switch (language) {
          'id' => 'Malam',
          'zh' => '夜晚',
          'ja' => '夜',
          _ => 'Evening',
        },
      _ => switch (language) {
          'id' => 'Minggu ini',
          'zh' => '本周',
          'ja' => '今週',
          _ => 'This week',
        },
    };
  }

  static String getReflectionContextLabel(String language) {
    return switch (language) {
      'id' => 'Konteks singkat',
      'en' => 'Quick context',
      'zh' => '简要背景',
      'ja' => '短い文脈',
      _ => 'Quick context',
    };
  }

  static String getReflectionReflectionHeading(String language) {
    return getThemeReflectionHeading(language);
  }

  static String getReflectionLoadError(String language) {
    return switch (language) {
      'id' => 'Renungan tidak dapat dimuat.',
      'en' => 'Could not load reflection.',
      'zh' => '无法加载思考内容。',
      'ja' => '黙想を読み込めませんでした。',
      _ => 'Could not load reflection.',
    };
  }

  static String getCatalogRetry(String language) {
    return switch (language) {
      'id' => 'Coba lagi',
      'en' => 'Try again',
      'zh' => '重试',
      'ja' => '再試行',
      _ => 'Try again',
    };
  }

  static String getScienceEmpty(String language) {
    return switch (language) {
      'id' => 'Belum ada topik dalam kategori ini.',
      'en' => 'No topics in this category yet.',
      'zh' => '此类别暂无主题。',
      'ja' => 'このカテゴリにはまだテーマがありません。',
      _ => 'No topics in this category yet.',
    };
  }

  static String getThemeCategoryLabel(String category, String language) {
    return switch (category) {
      'patience' => switch (language) {
          'id' => 'Sabar & ketenangan',
          'zh' => '忍耐与安宁',
          'ja' => '忍耐と心の平安',
          _ => 'Patience & calm',
        },
      'gratitude' => switch (language) {
          'id' => 'Syukur',
          'zh' => '感恩',
          'ja' => '感謝',
          _ => 'Gratitude',
        },
      'provision' => switch (language) {
          'id' => 'Rezeki & kecukupan',
          'zh' => '给养与足用',
          'ja' => '糧と足りる心',
          _ => 'Provision',
        },
      'family' => switch (language) {
          'id' => 'Keluarga',
          'zh' => '家庭',
          'ja' => '家族',
          _ => 'Family',
        },
      'trials' => switch (language) {
          'id' => 'Ujian & musibah',
          'zh' => '考验与灾难',
          'ja' => '試練と災難',
          _ => 'Trials & hardship',
        },
      'hope' => switch (language) {
          'id' => 'Harapan & tawakal',
          'zh' => '希望与托靠',
          'ja' => '希望と托靠',
          _ => 'Hope & trust',
        },
      'character' => switch (language) {
          'id' => 'Akhlak & diri',
          'zh' => '品性与内心',
          'ja' => '品性と心',
          _ => 'Character & self',
        },
      'hereafter' => switch (language) {
          'id' => 'Akhirat',
          'zh' => '后世',
          'ja' => '来世',
          _ => 'The Hereafter',
        },
      _ => category,
    };
  }

  static String getThemeTopicCount(int count, String language) {
    return getScienceTopicCount(count, language);
  }

  static String getThemeReflectionHeading(String language) {
    return switch (language) {
      'id' => 'Cara merenungkan',
      'en' => 'How to reflect',
      'zh' => '如何思考',
      'ja' => '味わい方',
      _ => 'How to reflect',
    };
  }

  static String formatThemeAyahLabel(int ayahCount, String language) {
    return switch (language) {
      'id' => '$ayahCount ayat',
      'zh' => '$ayahCount 节',
      'ja' => '$ayahCount 節',
      _ => '$ayahCount verses',
    };
  }

  static String getThemeLoadError(String language) {
    return switch (language) {
      'id' =>
        'Katalog tema hidup tidak dapat dimuat. Tutup aplikasi sepenuhnya lalu buka lagi.',
      'en' =>
        'Could not load the life themes catalog. Fully restart the app.',
      'zh' => '无法加载生活主题目录。请完全关闭后重新打开应用。',
      'ja' => '生活テーマの目録を読み込めませんでした。アプリを完全に終了して再起動してください。',
      _ => 'Could not load the life themes catalog. Fully restart the app.',
    };
  }

  static String getThemeEmpty(String language) {
    return getScienceEmpty(language);
  }

  static String getAsmaReflectionHeading(String language) {
    return switch (language) {
      'id' => 'Mengingat nama ini',
      'en' => 'Remembering this name',
      'zh' => '记念此名',
      'ja' => 'この御名を思う',
      _ => 'Remembering this name',
    };
  }

  static String getAsmaLoadError(String language) {
    return switch (language) {
      'id' =>
        'Katalog Asmaul Husna tidak dapat dimuat. Hentikan aplikasi, lalu jalankan ulang dari awal (flutter run). Hot reload tidak memuat berkas baru.',
      'en' =>
        'Could not load the Names of Allah catalog. Stop the app and run a full rebuild (flutter run). Hot reload does not bundle new files.',
      'zh' => '无法加载真主美名目录。请停止应用并完整重新安装（flutter run）。热重载不会打包新文件。',
      'ja' =>
        'アッラーの美名の目録を読み込めませんでした。アプリを停止し、完全に再ビルドしてください（flutter run）。ホットリロードでは新しいファイルは含まれません。',
      _ => 'Could not load the Names of Allah catalog. Stop the app and run a full rebuild (flutter run).',
    };
  }

  static String getExploreScrollHint(String language) {
    return switch (language) {
      'id' => 'Gulir untuk melihat lebih banyak',
      'en' => 'Scroll for more',
      'zh' => '向上滑动查看更多',
      'ja' => 'スクロールして続きを見る',
      _ => 'Scroll for more',
    };
  }

  static String getJuzAmmaTitle(String language) {
    return switch (language) {
      'id' => 'Juz Amma',
      'en' => 'Juz Amma',
      'zh' => '阿玛章',
      'ja' => 'ジュズ・アンマー',
      _ => 'Juz Amma',
    };
  }

  static String getJuzAmmaSubtitle(String language) {
    return switch (language) {
      'id' => 'Juz Amma — hafalan surat pendek (Juz 30)',
      'en' => 'Juz Amma — memorize the short surahs (Juz 30)',
      'zh' => '阿玛章 — 背诵短章（第30卷）',
      'ja' => 'ジュズ・アンマー — 短いスーラの暗誦（第30ジュズ）',
      _ => 'Juz Amma — memorize the short surahs (Juz 30)',
    };
  }

  /// Juz 30 is commonly called Juz Amma in the app UI.
  static String getJuzTitle(String language, int juzNo) {
    if (juzNo == 30) {
      return getJuzAmmaTitle(language);
    }
    return switch (language) {
      'id' => 'Juz $juzNo',
      'en' => 'Juz $juzNo',
      'zh' => '第$juzNo卷',
      'ja' => '第$juzNoジュズ',
      _ => 'Juz $juzNo',
    };
  }

  static String getJuzAmmaMethodTip(String language) {
    return switch (language) {
      'id' =>
        'Metode terstruktur: hari biasa hafalan baru (1 unit), Jumat setoran (mengulang), lalu beberapa hari memantapkan (tahsin). Setoran Jumat muncul otomatis di kartu tugas. Konsisten setiap hari.',
      'en' =>
        'Structured method: weekdays for new memorization (one unit), Friday setoran (review), then a few tahsin days to strengthen. Friday setoran appears in the task card. Stay consistent.',
      'zh' =>
        '结构化方法：平日背新内容（一个单元），周五复习（setoran），随后几天塔辛巩固。周五复习自动显示在任务卡片。每天坚持。',
      'ja' =>
        '構成された方法：平日は新しい暗誦（1単位）、金曜は復習（セットラン）、その後数日タフスィーンで定着。金曜の復習はタスクカードに表示されます。毎日続けましょう。',
      _ => 'Structured method: weekdays for new units, Friday setoran, then tahsin days.',
    };
  }

  static String getJuzAmmaModeProgram(String language) {
    return switch (language) {
      'id' => 'Program',
      'en' => 'Program',
      'zh' => '计划模式',
      'ja' => 'プログラム',
      _ => 'Program',
    };
  }

  static String getJuzAmmaModeFree(String language) {
    return switch (language) {
      'id' => 'Bebas',
      'en' => 'Free',
      'zh' => '自由模式',
      'ja' => '自由',
      _ => 'Free',
    };
  }

  static String getJuzAmmaStartProgram(String language) {
    return switch (language) {
      'id' => 'Mulai program',
      'en' => 'Start program',
      'zh' => '开始计划',
      'ja' => 'プログラムを始める',
      _ => 'Start program',
    };
  }

  static String getJuzAmmaTodayNew(String language) {
    return switch (language) {
      'id' => 'Hafalan baru hari ini',
      'en' => 'Today\'s new memorization',
      'zh' => '今日新背',
      'ja' => '今日の新しい暗誦',
      _ => 'Today\'s new memorization',
    };
  }

  static String getJuzAmmaTodayMurojaah(String language) {
    return switch (language) {
      'id' => 'Setoran Jumat',
      'en' => 'Friday setoran',
      'zh' => '周五复习',
      'ja' => '金曜セットラン',
      _ => 'Friday setoran',
    };
  }

  static String getJuzAmmaFridaySetoranHint(String language) {
    return switch (language) {
      'id' => 'Ulang semua hafalan yang sudah dipelajari minggu ini.',
      'en' => 'Review everything you memorized this week.',
      'zh' => '复习本周已背内容。',
      'ja' => '今週覚えた範囲を復習します。',
      _ => 'Review this week\'s memorization.',
    };
  }

  static String getJuzAmmaTodayTahsin(String language, int day, int total) {
    return switch (language) {
      'id' => 'Memantapkan hafalan — hari $day dari $total',
      'en' => 'Strengthen memorization — day $day of $total',
      'zh' => '巩固背诵 — 第 $day / $total 天',
      'ja' => '定着の日 — $day / $total 日目',
      _ => 'Strengthen — day $day of $total',
    };
  }

  static String getJuzAmmaProgramComplete(String language) {
    return switch (language) {
      'id' => 'Program selesai — terus ulang Juz Amma',
      'en' => 'Program complete — keep reviewing Juz Amma',
      'zh' => '计划完成 — 继续复习阿玛章',
      'ja' => 'プログラム完了 — ジュズ・アンマーを復習し続けましょう',
      _ => 'Program complete — keep reviewing',
    };
  }

  static String getJuzAmmaOpenTarget(String language) {
    return switch (language) {
      'id' => 'Buka hafalan hari ini',
      'en' => 'Open today\'s lesson',
      'zh' => '打开今日内容',
      'ja' => '今日の範囲を開く',
      _ => 'Open today\'s lesson',
    };
  }

  static String getJuzAmmaOpenFridaySetoran(String language) {
    return switch (language) {
      'id' => 'Mulai setoran Jumat',
      'en' => 'Start Friday setoran',
      'zh' => '开始周五复习',
      'ja' => '金曜セットランを始める',
      _ => 'Start Friday setoran',
    };
  }

  static String getJuzAmmaLibrarySummaryAction(String language) {
    return switch (language) {
      'id' => 'Buka program hafalan',
      'en' => 'Open memorization program',
      'zh' => '打开背诵计划',
      'ja' => '暗誦プログラムを開く',
      _ => 'Open memorization program',
    };
  }

  static String getJuzAmmaLibraryTodayLine(String language, String detail) {
    return switch (language) {
      'id' => 'Hari ini: $detail',
      'en' => 'Today: $detail',
      'zh' => '今日：$detail',
      'ja' => '今日：$detail',
      _ => 'Today: $detail',
    };
  }

  static String formatJuzAmmaUnitShort(
    String language,
    String surahName,
    int unitNo,
  ) {
    return switch (language) {
      'id' => '$surahName (unit $unitNo)',
      'en' => '$surahName (unit $unitNo)',
      'zh' => '$surahName（第 $unitNo 单元）',
      'ja' => '$surahName（ユニット $unitNo）',
      _ => '$surahName (unit $unitNo)',
    };
  }

  static String getJuzAmmaLibraryFridaySetoranLine(
    String language,
    int done,
    int total,
  ) {
    return switch (language) {
      'id' => '[Jumat] Setoran: $done/$total surat minggu ini',
      'en' => '[Friday] Setoran: $done/$total surahs this week',
      'zh' => '[周五] 复习：本周 $done/$total 个苏拉',
      'ja' => '[金曜] セットラン：今週 $done/$total スーラ',
      _ => '[Friday] Setoran: $done/$total surahs this week',
    };
  }

  static String getFridaySetoranProgressSubtitle(
    String language,
    int done,
    int total,
  ) {
    return switch (language) {
      'id' =>
        '$done dari $total sudah ditandai — lihat centang di antrian setoran.',
      'en' =>
        '$done of $total marked done — see checkmarks in the setoran queue.',
      'zh' => '已标记 $done/$total — 在复习列表中查看勾选。',
      'ja' => '$done / $total 件済み — キューでチェックを確認。',
      _ => '$done of $total marked — see the setoran queue.',
    };
  }

  static String getFridaySetoranProgressTitle(String language) {
    return switch (language) {
      'id' => 'Progres setoran minggu ini',
      'en' => 'This week\'s setoran progress',
      'zh' => '本周复习进度',
      'ja' => '今週のセットラン進捗',
      _ => 'This week\'s setoran progress',
    };
  }

  static String getLibraryProgramSectionTitle(String language) {
    return switch (language) {
      'id' => 'Program hafalan',
      'en' => 'Memorization program',
      'zh' => '背诵计划',
      'ja' => '暗誦プログラム',
      _ => 'Memorization program',
    };
  }

  static String getLibraryReadingCollectionTitle(String language) {
    return switch (language) {
      'id' => 'Koleksi bacaan',
      'en' => 'Reading collection',
      'zh' => '阅读收藏',
      'ja' => '読書コレクション',
      _ => 'Reading collection',
    };
  }

  static String getJuzAmmaLibraryFridaySetoranShort(
    String language,
    int done,
    int total,
  ) {
    return switch (language) {
      'id' => 'Setoran $done/$total',
      'en' => 'Setoran $done/$total',
      'zh' => '复习 $done/$total',
      'ja' => 'セットラン $done/$total',
      _ => 'Setoran $done/$total',
    };
  }

  static String formatJuzAmmaLibraryCollapsedStrip(
    String language,
    int percent,
    String detail,
  ) {
    return switch (language) {
      'id' => 'Juz Amma · $percent% · $detail',
      'en' => 'Juz Amma · $percent% · $detail',
      'zh' => '阿玛章 · $percent% · $detail',
      'ja' => 'ジュズ・アンマー · $percent% · $detail',
      _ => 'Juz Amma · $percent% · $detail',
    };
  }

  static String getJuzAmmaLibraryCollapseHint(String language) {
    return switch (language) {
      'id' => 'Ciutkan program hafalan',
      'en' => 'Collapse memorization program',
      'zh' => '收起背诵计划',
      'ja' => '暗誦プログラムを折りたたむ',
      _ => 'Collapse memorization program',
    };
  }

  static String getJuzAmmaLibraryExpandHint(String language) {
    return switch (language) {
      'id' => 'Buka program hafalan',
      'en' => 'Expand memorization program',
      'zh' => '展开背诵计划',
      'ja' => '暗誦プログラムを展開',
      _ => 'Expand memorization program',
    };
  }

  static String getFridaySetoranBannerTitle(String language) {
    return switch (language) {
      'id' => 'Hari Jumat — waktunya setoran',
      'en' => 'Friday — time for setoran',
      'zh' => '周五 — 复习时间',
      'ja' => '金曜 — セットランの日',
      _ => 'Friday — time for setoran',
    };
  }

  static String getFridaySetoranBannerBody(String language, int pending) {
    return switch (language) {
      'id' =>
        '$pending hafalan minggu ini belum disetor. Latihan mandiri — bukan pengganti guru.',
      'en' =>
        '$pending items from this week not yet setoran. Self-practice — not a substitute for a teacher.',
      'zh' => '本周还有 $pending 项未复习。自主练习，不能替代老师。',
      'ja' => '今週 $pending 件が未セットラン。自主練習であり、師匠の代わりにはなりません。',
      _ => '$pending items pending setoran this week.',
    };
  }

  static String getFridaySetoranScreenTitle(String language) {
    return switch (language) {
      'id' => 'Setoran Jumat',
      'en' => 'Friday setoran',
      'zh' => '周五复习',
      'ja' => '金曜セットラン',
      _ => 'Friday setoran',
    };
  }

  static String getFridaySetoranQueueEmpty(String language) {
    return switch (language) {
      'id' =>
        'Belum ada hafalan untuk disetor. Tandai ayat yang sudah dihafal di daftar surah Juz Amma.',
      'en' =>
        'Nothing to setoran yet. Mark memorized ayahs on the Juz Amma surah list.',
      'zh' => '暂无可复习内容。请在 Juz Amma 列表中标记已背经文。',
      'ja' => 'セットランする項目がありません。Juz Amma で暗誦済みの節をマークしてください。',
      _ => 'Nothing to setoran yet. Mark memorized ayahs in Juz Amma.',
    };
  }

  static String getFridaySetoranQueueHint(String language) {
    return switch (language) {
      'id' =>
        'Ulang hafalan Sabtu–Kamis minggu ini. Tandai "sudah disetor" setelah latihan (catatan pribadi).',
      'en' =>
        'Review Sat–Thu memorization. Mark "setoran done" after practice (personal note).',
      'zh' => '复习本周六至周四内容。练习后可标记“已复习”（个人记录）。',
      'ja' =>
        '土〜木曜の暗誦を復習。練習後に「済み」とマーク（個人メモ）。',
      _ => 'Review this week\'s units. Mark done after self-practice.',
    };
  }

  static String getFridaySetoranDone(String language) {
    return switch (language) {
      'id' => 'Sudah disetor',
      'en' => 'Setoran done',
      'zh' => '已复习',
      'ja' => 'セットラン済み',
      _ => 'Setoran done',
    };
  }

  static String getFridaySetoranMarkDone(String language) {
    return switch (language) {
      'id' => 'Tandai sudah disetor',
      'en' => 'Mark setoran done',
      'zh' => '标记已复习',
      'ja' => 'セットラン済みにする',
      _ => 'Mark setoran done',
    };
  }

  static String getFridaySetoranUnmark(String language) {
    return switch (language) {
      'id' => 'Batalkan tanda setoran',
      'en' => 'Undo setoran mark',
      'zh' => '取消复习标记',
      'ja' => 'マークを取り消す',
      _ => 'Undo setoran mark',
    };
  }

  static String getSetoranSessionTitle(String language) {
    return switch (language) {
      'id' => 'Mode setoran',
      'en' => 'Setoran mode',
      'zh' => '复习模式',
      'ja' => 'セットランモード',
      _ => 'Setoran mode',
    };
  }

  static String getSetoranHideText(String language) {
    return switch (language) {
      'id' => 'Sembunyikan teks',
      'en' => 'Hide text',
      'zh' => '隐藏文字',
      'ja' => '文字を隠す',
      _ => 'Hide text',
    };
  }

  static String getSetoranShowText(String language) {
    return switch (language) {
      'id' => 'Tampilkan teks',
      'en' => 'Show text',
      'zh' => '显示文字',
      'ja' => '文字を表示',
      _ => 'Show text',
    };
  }

  static String getSetoranPlayAyah(String language) {
    return switch (language) {
      'id' => 'Putar audio ayat',
      'en' => 'Play ayah audio',
      'zh' => '播放经文音频',
      'ja' => '音節を再生',
      _ => 'Play ayah audio',
    };
  }

  static String getSetoranNextAyah(String language) {
    return switch (language) {
      'id' => 'Ayat berikutnya',
      'en' => 'Next ayah',
      'zh' => '下一节',
      'ja' => '次の節',
      _ => 'Next ayah',
    };
  }

  static String getSetoranPrevAyah(String language) {
    return switch (language) {
      'id' => 'Ayat sebelumnya',
      'en' => 'Previous ayah',
      'zh' => '上一节',
      'ja' => '前の節',
      _ => 'Previous ayah',
    };
  }

  static String getSetoranTeacherNote(String language) {
    return switch (language) {
      'id' =>
        'Catatan mandiri — setoran ke guru tetap dilakukan di luar aplikasi.',
      'en' =>
        'Self-practice only — setoran with a teacher happens outside the app.',
      'zh' => '自主练习记录，向老师复习请在应用外进行。',
      'ja' =>
        '自主練習の記録です。師匠へのセットランはアプリ外で行ってください。',
      _ => 'Self-practice note — teacher setoran is outside the app.',
    };
  }

  static String getSetoranFadeModeHint(String language) {
    return switch (language) {
      'id' =>
        'Baca dari hafalan — teks samar seperti sketsa. Ketuk Cek bacaan, baca ayat, lalu Selesai cek. Benar = tebal jelas; salah = merah.',
      'en' =>
        'Recite from memory — faint sketch text. Tap Check recitation, recite, then Finish check. Correct = bold; wrong = red.',
      'zh' => '凭记忆诵读 — 淡影文字。点核对诵读，诵读后点完成。正确加粗，错误变红。',
      'ja' => '暗誦で読む — 薄い文字。読みチェック→読む→完了。正しければ太字、誤りは赤。',
      _ => 'Recite from memory. Check recitation, then finish. Correct = bold; wrong = red.',
    };
  }

  static String getSetoranCheckOnlyHint(String language) {
    return switch (language) {
      'id' =>
        'Atau pakai Sudah benar / Perlu ulang jika tanpa internet',
      'en' => 'Or use Already correct / Need repeat when offline',
      'zh' => '无网络时可用手动标记',
      'ja' => 'オフライン時は手動で判定できます',
      _ => 'Or mark manually when offline',
    };
  }

  static String getSetoranRecordingActiveHint(String language) {
    return switch (language) {
      'id' => 'Sedang merekam — ketuk Stop rekam saat selesai',
      'en' => 'Recording — tap Stop when finished',
      'zh' => '正在录音 — 完成后点停止',
      'ja' => '録音中 — 終わったら停止をタップ',
      _ => 'Recording — tap Stop when finished',
    };
  }

  static String getSetoranRecordingSavedThenCheck(String language) {
    return switch (language) {
      'id' => 'Rekaman tersimpan — putar ulang atau ketuk Cek bacaan',
      'en' => 'Recording saved — replay or tap Check recitation',
      'zh' => '录音已保存 — 回放或点核对诵读',
      'ja' => '録音を保存 — 再生するか読みチェックをタップ',
      _ => 'Recording saved — replay or check recitation',
    };
  }

  static String getSetoranCheckRecitation(String language) {
    return switch (language) {
      'id' => 'Cek bacaan',
      'en' => 'Check recitation',
      'zh' => '核对诵读',
      'ja' => '読みをチェック',
      _ => 'Check recitation',
    };
  }

  static String getSetoranCheckListeningHint(String language) {
    return switch (language) {
      'id' => 'Baca ayat sekarang — teks akan tebal jika cocok, merah jika salah',
      'en' => 'Recite the ayah now — text turns bold if correct, red if wrong',
      'zh' => '请诵读本节 — 正确则加粗，错误则变红',
      'ja' => '節を読んでください — 正しければ太字、誤りは赤',
      _ => 'Recite now — bold if correct, red if wrong',
    };
  }

  static String getSetoranFinishCheck(String language) {
    return switch (language) {
      'id' => 'Selesai cek',
      'en' => 'Finish check',
      'zh' => '完成核对',
      'ja' => 'チェック完了',
      _ => 'Finish check',
    };
  }

  static String formatSetoranHeardTranscript(String language, String text) {
    return switch (language) {
      'id' => 'Terdeteksi: $text',
      'en' => 'Heard: $text',
      'zh' => '识别到：$text',
      'ja' => '認識：$text',
      _ => 'Heard: $text',
    };
  }

  static String formatSetoranMatchScore(String language, double score) {
    final pct = (score * 100).round();
    return switch (language) {
      'id' => 'Kemiripan: $pct%',
      'en' => 'Match: $pct%',
      'zh' => '匹配度：$pct%',
      'ja' => '一致度：$pct%',
      _ => 'Match: $pct%',
    };
  }

  static String getSetoranAfterPlaybackCheckHint(String language) {
    return switch (language) {
      'id' => 'Sudah dengar rekaman? Ketuk Cek bacaan dan baca ayat sekali lagi',
      'en' => 'Heard your recording? Tap Check recitation and recite once more',
      'zh' => '听完录音？点核对诵读并再读一遍',
      'ja' => '録音を聞き終えたら読みチェックで再度読んでください',
      _ => 'Heard recording? Tap Check recitation and recite again',
    };
  }

  static String getSetoranSpeechChecking(String language) {
    return switch (language) {
      'id' => 'Memeriksa bacaan...',
      'en' => 'Checking recitation...',
      'zh' => '正在核对诵读...',
      'ja' => '読みを確認中...',
      _ => 'Checking recitation...',
    };
  }

  static String getSetoranSpeechCorrect(String language) {
    return switch (language) {
      'id' => 'Bacaan cocok — ayat menjadi jelas',
      'en' => 'Recitation matched — ayah revealed',
      'zh' => '诵读匹配 — 经文已显示',
      'ja' => '一致 — 節を表示しました',
      _ => 'Recitation matched — ayah revealed',
    };
  }

  static String getSetoranSpeechRetry(String language) {
    return switch (language) {
      'id' => 'Bacaan belum cocok — coba ulang',
      'en' => 'Recitation did not match — try again',
      'zh' => '诵读未匹配 — 请重试',
      'ja' => '一致しません — やり直してください',
      _ => 'Recitation did not match — try again',
    };
  }

  static String getSetoranSpeechUncertain(String language) {
    return switch (language) {
      'id' =>
        'Suara tidak jelas — tandai manual atau rekam ulang',
      'en' =>
        'Could not hear clearly — mark manually or record again',
      'zh' => '听不清楚 — 请手动标记或重新录音',
      'ja' => '聞き取れません — 手動で判定するか再録音してください',
      _ => 'Could not hear clearly — mark manually or record again',
    };
  }

  static String getSetoranSpeechUnavailable(String language) {
    return switch (language) {
      'id' =>
        'Pengenalan suara tidak tersedia — gunakan tandai manual',
      'en' =>
        'Speech recognition unavailable — use manual marking',
      'zh' => '语音识别不可用 — 请手动标记',
      'ja' => '音声認識が使えません — 手動で判定してください',
      _ => 'Speech recognition unavailable — mark manually',
    };
  }

  static String getSetoranSpeechOnlineHint(String language) {
    return switch (language) {
      'id' =>
        'Cek bacaan pakai internet (Wi‑Fi/data). Arab offline tidak wajib di Pixel.',
      'en' =>
        'Check recitation needs internet (Wi‑Fi/data). Offline Arabic is optional on Pixel.',
      'zh' => '核对诵读需要网络。Pixel 上阿拉伯语离线包不是必需的。',
      'ja' => '読みチェックはインターネットが必要です。オフラインアラビア語は必須ではありません。',
      _ => 'Check recitation needs internet. Offline Arabic pack is optional.',
    };
  }

  static String getSetoranSpeechArabicRequired(String language) {
    return switch (language) {
      'id' =>
        'Paket suara Arab belum terpasang. Tidak perlu ubah bahasa sistem — cukup tambah Arab di pengenalan suara Google (lihat petunjuk di atas). Atau gunakan Sudah benar / Perlu ulang.',
      'en' =>
        'Arabic voice pack is not installed. No need to change system language — add Arabic in Google voice input only, or mark manually.',
      'zh' => '未安装阿拉伯语语音包。无需更改系统语言 — 仅在 Google 语音输入中添加阿拉伯语，或手动标记。',
      'ja' =>
        'アラビア語の音声パックがありません。システム言語は変更不要 — Google 音声入力にアラビア語を追加するか、手動で判定してください。',
      _ => 'Arabic voice pack is not installed. Add Arabic in voice input settings, or mark manually.',
    };
  }

  /// Shown when Arabic STT pack is missing — clarifies voice-only setup.
  static String getSetoranArabicVoiceSetupHint(String language) {
    return switch (language) {
      'id' =>
        'Arab sudah dipilih di Google voice typing? Cek bacaan pakai internet '
        '(Wi‑Fi/data) — paket offline Arab sering tidak ada di Pixel, itu normal.',
      'en' =>
        'Auto check needs an Arabic voice pack (not a system language change). '
        'New Gboard builds often hide Languages — use the steps below.',
      'zh' => '自动核对需要阿拉伯语语音包。新版 Gboard 可能没有 Languages 菜单 — 请按下方步骤操作。',
      'ja' =>
        '自動チェックにはアラビア語音声パックが必要です。'
        '新しい Gboard では Languages がない場合があります — 下の手順を参照。',
      _ => 'Auto check needs Arabic voice input. See steps below.',
    };
  }

  static String getSetoranArabicVoiceSetupSteps(String language) {
    return switch (language) {
      'id' =>
        'Pixel & Samsung (tanpa ubah bahasa HP):\n\n'
        'A) Google voice typing (paling umum)\n'
        'Settings → System → Languages & input\n'
        '→ On-screen keyboard → Google voice typing\n'
        '→ Offline speech recognition → tab All\n'
        '→ centang Arabic (Saudi Arabia) / العربية (السعودية)\n'
        '  (paling cocok untuk bacaan Qur\'an; Egypt juga OK)\n\n'
        'Offline speech: Arab sering TIDAK ada di daftar download Pixel — '
        'abaikan, cukup langkah A + internet saat Cek bacaan.\n\n'
        'B) Lewat tile Google\n'
        'Settings → Google → All services\n'
        '→ Search, Assistant & Voice → Voice\n'
        '→ Offline speech recognition → Arabic\n\n'
        'C) Samsung khusus\n'
        'Settings → General management\n'
        '→ Keyboard list and default → Google voice typing\n'
        '→ Offline speech recognition / Add language\n\n'
        'D) Update dulu\n'
        'Play Store: update Google, Gboard, '
        'Speech Services by Google\n\n'
        'Setelah download: kembali ke app → ketuk Cek lagi.',
      'en' =>
        'Pixel & Samsung (no system language change):\n\n'
        'A) Google voice typing\n'
        'Settings → System → Languages & input\n'
        '→ On-screen keyboard → Google voice typing\n'
        '→ Offline speech recognition → All\n'
        '→ Arabic (Saudi Arabia) preferred for Qur\'an\n\n'
        'B) Google settings tile\n'
        'Settings → Google → Search, Assistant & Voice → Voice\n'
        '→ Offline speech recognition → Arabic\n\n'
        'C) Samsung\n'
        'Settings → General management → Keyboard list and default\n'
        '→ Google voice typing → Offline speech recognition\n\n'
        'D) Update Google, Gboard, Speech Services by Google\n\n'
        'Then return here and tap Check again.',
      'zh' =>
        'Pixel 与 Samsung：\n'
        '设置 → 系统 → 语言和输入法 → 屏幕键盘 → Google 语音输入\n'
        '→ 离线语音识别 → 全部 → 下载阿拉伯语\n\n'
        '或：设置 → Google → 语音 → 离线语音识别\n\n'
        '完成后返回应用点“重新检测”。',
      'ja' =>
        'Pixel / Samsung:\n'
        '設定 → システム → 言語と入力 → 画面キーボード\n'
        '→ Google 音声入力 → オフライン音声認識 → アラビア語\n\n'
        'または 設定 → Google → 音声 → オフライン音声認識\n\n'
        '戻って「再確認」をタップ。',
      _ => 'Settings → Languages & input → Google voice typing\n'
          '→ Offline speech recognition → Arabic',
    };
  }

  static String getSetoranArabicVoiceOpenSettings(String language) {
    return switch (language) {
      'id' => 'Buka pengaturan suara',
      'en' => 'Open voice settings',
      'zh' => '打开语音设置',
      'ja' => '音声設定を開く',
      _ => 'Open voice settings',
    };
  }

  static String getSetoranArabicVoiceRecheck(String language) {
    return switch (language) {
      'id' => 'Cek lagi',
      'en' => 'Check again',
      'zh' => '重新检测',
      'ja' => '再確認',
      _ => 'Check again',
    };
  }

  static String getSetoranArabicVoiceReady(String language, String locale) {
    return switch (language) {
      'id' => 'Suara Arab siap ($locale) — Cek bacaan bisa dipakai',
      'en' => 'Arabic voice ready ($locale) — you can check recitation',
      'zh' => '阿拉伯语语音已就绪（$locale）— 可以核对诵读',
      'ja' => 'アラビア語音声の準備完了（$locale）',
      _ => 'Arabic voice ready ($locale)',
    };
  }

  static String getSetoranArabicVoiceRecheckOk(String language, String locale) {
    return switch (language) {
      'id' => 'Terdeteksi: $locale — silakan Cek bacaan',
      'en' => 'Detected: $locale — tap Check recitation',
      'zh' => '已检测到：$locale — 请点核对诵读',
      'ja' => '検出：$locale — 読みチェックをタップ',
      _ => 'Detected: $locale',
    };
  }

  static String getSetoranArabicVoiceRecheckFail(String language) {
    return switch (language) {
      'id' =>
        'Belum terdeteksi — tambah Arabic (Saudi Arabia) di Google voice typing, lalu Cek lagi',
      'en' =>
        'Not detected yet — add Arabic (Saudi Arabia) in Google voice typing, then Check again',
      'zh' => '未检测到 — 请在 Google 语音输入中添加阿拉伯语后重新检测',
      'ja' => '未検出 — Google 音声入力でアラビア語を追加して再確認',
      _ => 'Arabic voice not detected yet',
    };
  }

  static String getSetoranArabicVoiceBlockedTitle(String language) {
    return switch (language) {
      'id' => 'Suara Arab belum siap',
      'en' => 'Arabic voice not ready',
      'zh' => '阿拉伯语语音未就绪',
      'ja' => 'アラビア語音声が未設定',
      _ => 'Arabic voice not ready',
    };
  }

  static String getSetoranArabicVoiceBlockedBody(String language) {
    return switch (language) {
      'id' =>
        'HP belum mendeteksi bahasa Arab untuk pengenalan suara. '
        'Pasang dulu di Google voice typing (Arabic Saudi Arabia), ketuk Cek lagi, '
        'baru pakai Cek bacaan. Atau gunakan Sudah benar / Perlu ulang manual.',
      'en' =>
        'This device has not registered Arabic for speech recognition. '
        'Add Arabic (Saudi Arabia) in Google voice typing, tap Check again, '
        'then use Check recitation — or mark manually.',
      'zh' => '设备尚未注册阿拉伯语语音识别。请先添加阿拉伯语并重新检测，或手动标记。',
      'ja' =>
        '端末がアラビア語音声認識を検出していません。設定後に再確認するか、手動で判定してください。',
      _ => 'Add Arabic voice input first, or mark manually.',
    };
  }

  static String getSetoranArabicVoiceShowSteps(String language) {
    return switch (language) {
      'id' => 'Lihat langkah',
      'en' => 'See steps',
      'zh' => '查看步骤',
      'ja' => '手順を見る',
      _ => 'See steps',
    };
  }

  static String getSetoranTajwidClean(String language) {
    return switch (language) {
      'id' => 'Tajwid: tidak ada catatan khusus',
      'en' => 'Tajweed: no specific notes',
      'zh' => '塔吉维德：无特别说明',
      'ja' => 'タジウィード：特記事項なし',
      _ => 'Tajweed: no specific notes',
    };
  }

  static String formatSetoranTajwidIssueCount(String language, int count) {
    return switch (language) {
      'id' => '$count catatan tajwid — ketuk untuk detail',
      'en' => '$count tajweed notes — tap for details',
      'zh' => '$count 条塔吉维德说明 — 点击查看',
      'ja' => 'タジウィードの注意 $count 件 — タップで詳細',
      _ => '$count tajweed notes — tap for details',
    };
  }

  static String getSetoranTajwidPerWord(String language) {
    return switch (language) {
      'id' => 'Per kata',
      'en' => 'Per word',
      'zh' => '逐词',
      'ja' => '単語ごと',
      _ => 'Per word',
    };
  }

  static String getSetoranTajwidLaamShams(String language) {
    return switch (language) {
      'id' => 'Lam Syamsiyah',
      'en' => 'Lam shamsiyah',
      'zh' => '太阳 Lam',
      'ja' => '太陽のラーム',
      _ => 'Lam shamsiyah',
    };
  }

  static String getSetoranTajwidGhunnah(String language) {
    return switch (language) {
      'id' => 'Ghunnah',
      'en' => 'Ghunnah',
      'zh' => '鼻音',
      'ja' => 'グンナ',
      _ => 'Ghunnah',
    };
  }

  static String getSetoranTajwidMajor(String language) {
    return switch (language) {
      'id' => 'Utama',
      'en' => 'Major',
      'zh' => '主要',
      'ja' => '重要',
      _ => 'Major',
    };
  }

  static String getSetoranTajwidMinor(String language) {
    return switch (language) {
      'id' => 'Ringan',
      'en' => 'Minor',
      'zh' => '次要',
      'ja' => '軽微',
      _ => 'Minor',
    };
  }

  static String getSetoranTajwidExpected(String language) {
    return switch (language) {
      'id' => 'Diharapkan',
      'en' => 'Expected',
      'zh' => '期望',
      'ja' => '期待',
      _ => 'Expected',
    };
  }

  static String getSetoranTajwidHeard(String language) {
    return switch (language) {
      'id' => 'Terdengar',
      'en' => 'Heard',
      'zh' => '听到',
      'ja' => '認識',
      _ => 'Heard',
    };
  }

  static String getSetoranTajwidMadLazimRush(String language) {
    return switch (language) {
      'id' =>
        'Bacaan mungkin terlalu cepat. Mad lazim wajib 6 harakat — lebih panjang dari mad lainnya.',
      'en' =>
        'Recitation may be too fast. Madd lazim requires 6 counts — longer than other madd.',
      'zh' => '诵读可能过快。必要长音需 6 拍。',
      'ja' => '読みが速すぎる可能性があります。ラズムは6拍必要です。',
      _ => 'Recitation may be too fast for madd lazim.',
    };
  }

  static String getSurahHeaderQulPreviewBadge(String language) {
    return switch (language) {
      'id' => 'Mockup QUL',
      'en' => 'QUL preview',
      'zh' => 'QUL 预览',
      'ja' => 'QULプレビュー',
      _ => 'QUL preview',
    };
  }

  static String getSurahHeaderAboutSurah(String language) {
    return switch (language) {
      'id' => 'Tentang surat',
      'en' => 'About this surah',
      'zh' => '关于此章',
      'ja' => 'このスーラについて',
      _ => 'About this surah',
    };
  }

  static String getSurahHeaderLangEnglish(String language) {
    return switch (language) {
      'id' => 'Bahasa Inggris',
      'en' => 'English',
      'zh' => '英语',
      'ja' => '英語',
      _ => 'English',
    };
  }

  static String getSurahHeaderLangIndonesian(String language) {
    return switch (language) {
      'id' => 'Bahasa Indonesia',
      'en' => 'Indonesian',
      'zh' => '印尼语',
      'ja' => 'インドネシア語',
      _ => 'Indonesian',
    };
  }

  static String getSurahHeaderQulInfoError(String language) {
    return switch (language) {
      'id' => 'Gagal memuat info surat QUL.',
      'en' => 'Could not load QUL surah info.',
      'zh' => '无法加载 QUL 章节信息。',
      'ja' => 'QULのスーラ情報を読み込めませんでした。',
      _ => 'Could not load QUL surah info.',
    };
  }

  static String getSurahHeaderQulInfoMissing(String language) {
    return switch (language) {
      'id' => 'Info surat belum tersedia untuk surat ini.',
      'en' => 'Surah info not available for this surah.',
      'zh' => '此章信息不可用。',
      'ja' => 'このスーラの情報はありません。',
      _ => 'Surah info not available.',
    };
  }

  static String getSurahMetaMeccan(String language) {
    return switch (language) {
      'id' => 'Makkiyah',
      'en' => 'Meccan',
      'zh' => '麦加章',
      'ja' => 'マッカ',
      _ => 'Meccan',
    };
  }

  static String getSurahMetaMedinan(String language) {
    return switch (language) {
      'id' => 'Madaniyah',
      'en' => 'Medinan',
      'zh' => '麦地那章',
      'ja' => 'マディーナ',
      _ => 'Medinan',
    };
  }

  static String formatSurahVerseCount(String language, int count) {
    return switch (language) {
      'id' => '$count ayat',
      'en' => '$count verses',
      'zh' => '$count 节',
      'ja' => '$count 節',
      _ => '$count verses',
    };
  }

  static String getSetoranSummaryTitle(String language) {
    return switch (language) {
      'id' => 'Ringkasan setoran',
      'en' => 'Recitation summary',
      'zh' => '诵读总结',
      'ja' => 'セットラン要約',
      _ => 'Recitation summary',
    };
  }

  static String getSetoranSummaryReady(String language) {
    return switch (language) {
      'id' => 'Siap disetor',
      'en' => 'Ready to submit',
      'zh' => '可以提交',
      'ja' => '提出可能',
      _ => 'Ready to submit',
    };
  }

  static String getSetoranSummaryNeedsWork(String language) {
    return switch (language) {
      'id' => 'Perlu perbaikan',
      'en' => 'Needs improvement',
      'zh' => '需要改进',
      'ja' => '要改善',
      _ => 'Needs improvement',
    };
  }

  static String getSetoranSummaryAyahProgress(String language) {
    return switch (language) {
      'id' => 'Ayat selesai',
      'en' => 'Ayahs done',
      'zh' => '已完成经文',
      'ja' => '完了した節',
      _ => 'Ayahs done',
    };
  }

  static String getSetoranSummaryTextScore(String language) {
    return switch (language) {
      'id' => 'Teks',
      'en' => 'Text',
      'zh' => '文本',
      'ja' => 'テキスト',
      _ => 'Text',
    };
  }

  static String getSetoranSummaryTajwidScore(String language) {
    return switch (language) {
      'id' => 'Tajwid',
      'en' => 'Tajweed',
      'zh' => '塔吉维德',
      'ja' => 'タジウィード',
      _ => 'Tajweed',
    };
  }

  static String getSetoranSummaryMainNotes(String language) {
    return switch (language) {
      'id' => 'Catatan tajwid utama',
      'en' => 'Main tajweed notes',
      'zh' => '主要塔吉维德说明',
      'ja' => '主なタジウィードの注意',
      _ => 'Main tajweed notes',
    };
  }

  static String getSetoranSummaryRetryAyahs(String language) {
    return switch (language) {
      'id' => 'Ayat perlu diulang',
      'en' => 'Ayahs to retry',
      'zh' => '需重试的经文',
      'ja' => 'やり直す節',
      _ => 'Ayahs to retry',
    };
  }

  static String formatSetoranSummaryErrorCount(String language, int count) {
    return switch (language) {
      'id' => '$count ayat belum benar — gunakan Coba lagi',
      'en' => '$count ayah(s) not correct — use Try again',
      'zh' => '$count 节尚未正确 — 请重试',
      'ja' => '未達成の節 $count — もう一度お試しください',
      _ => '$count ayah(s) not correct',
    };
  }

  static String getSetoranSummaryReviewHint(String language) {
    return switch (language) {
      'id' =>
        'Beberapa ayat sudah benar tetapi masih ada catatan tajwid. Anda boleh lanjut menandai setoran atau ulang ayat lemah.',
      'en' =>
        'Some ayahs are correct but tajweed notes remain. You may mark done or retry weaker ayahs.',
      'zh' => '部分经文已正确但仍有塔吉维德说明。可提交或重试薄弱经文。',
      'ja' =>
        '正解の節もありますがタジウィードの注意があります。提出するか弱い節をやり直せます。',
      _ => 'You may mark done or retry weaker ayahs.',
    };
  }

  static String getSetoranSummaryTryAgain(String language) {
    return switch (language) {
      'id' => 'Coba lagi',
      'en' => 'Try again',
      'zh' => '再试',
      'ja' => 'もう一度',
      _ => 'Try again',
    };
  }

  static String getSetoranSummaryOpen(String language) {
    return switch (language) {
      'id' => 'Lihat ringkasan',
      'en' => 'View summary',
      'zh' => '查看总结',
      'ja' => '要約を見る',
      _ => 'View summary',
    };
  }

  static String getSetoranSummaryBannerBody(
    String language,
    int done,
    int total,
    int noteCount,
  ) {
    return switch (language) {
      'id' =>
        'Anda menyelesaikan $done dari $total ayat. '
        '${noteCount > 0 ? 'Ada $noteCount catatan tajwid untuk dipelajari.' : 'Tidak ada catatan tajwid khusus.'}',
      'en' =>
        'You completed $done of $total ayahs. '
        '${noteCount > 0 ? 'There are $noteCount tajweed notes to review.' : 'No specific tajweed notes.'}',
      'zh' =>
        '已完成 $done/$total 节。'
        '${noteCount > 0 ? '有 $noteCount 条塔吉维德说明可供复习。' : '无特别塔吉维德说明。'}',
      'ja' =>
        '$total 節中 $done 節を完了しました。'
        '${noteCount > 0 ? 'タジウィードの注意が $noteCount 件あります。' : '特記事項はありません。'}',
      _ => 'Completed $done of $total ayahs.',
    };
  }

  static String formatSetoranSummaryAyahLabel(String language, int ayahNo) {
    return switch (language) {
      'id' => 'Ayat $ayahNo',
      'en' => 'Ayah $ayahNo',
      'zh' => '第 $ayahNo 节',
      'ja' => '第 $ayahNo 節',
      _ => 'Ayah $ayahNo',
    };
  }

  static String getSetoranTajwidScoreLabel(String language) {
    return switch (language) {
      'id' => 'Skor tajwid:',
      'en' => 'Tajweed score:',
      'zh' => '塔吉维德得分：',
      'ja' => 'タジウィードスコア：',
      _ => 'Tajweed score:',
    };
  }

  static String getSetoranSpeechWrongLanguage(String language) {
    return switch (language) {
      'id' =>
        'Bukan bahasa Arab — pasang bahasa Arab di pengenalan suara, atau gunakan Sudah benar / Perlu ulang',
      'en' =>
        'Not Arabic — install Arabic speech recognition or use manual buttons',
      'zh' => '非阿拉伯语识别 — 请安装阿拉伯语或手动标记',
      'ja' => 'アラビア語ではありません — 手動で判定してください',
      _ => 'Not recognized as Arabic',
    };
  }

  static String getSetoranRecordingEmpty(String language) {
    return switch (language) {
      'id' => 'Rekaman kosong — coba rekam lagi lebih dekat ke mic',
      'en' => 'Recording is empty — try again closer to the mic',
      'zh' => '录音为空 — 请靠近麦克风重试',
      'ja' => '録音が空です — マイクに近づけて再試行してください',
      _ => 'Recording is empty — try again',
    };
  }

  static String getSetoranPlaybackFailed(String language) {
    return switch (language) {
      'id' => 'Gagal memutar rekaman — coba rekam ulang',
      'en' => 'Could not play recording — try recording again',
      'zh' => '无法播放录音 — 请重新录制',
      'ja' => '再生できません — 再録音してください',
      _ => 'Playback failed',
    };
  }

  static String getSetoranPlaybackRerecordHint(String language) {
    return switch (language) {
      'id' =>
        'Rekaman lama tidak bisa diputar — ketuk mic, rekam ulang, lalu Putar rekaman',
      'en' =>
        'Old recording cannot play — tap mic, record again, then Play recording',
      'zh' => '旧录音无法播放 — 请重新录制后再播放',
      'ja' => '古い録音は再生できません — 再録音してください',
      _ => 'Please record again, then play',
    };
  }

  static String getSetoranAyahCorrect(String language) {
    return switch (language) {
      'id' => 'Sudah benar',
      'en' => 'Correct',
      'zh' => '读对了',
      'ja' => '正しい',
      _ => 'Correct',
    };
  }

  static String getSetoranAyahRetry(String language) {
    return switch (language) {
      'id' => 'Perlu ulang',
      'en' => 'Try again',
      'zh' => '需要重读',
      'ja' => 'やり直す',
      _ => 'Try again',
    };
  }

  static String getSetoranAyahReset(String language) {
    return switch (language) {
      'id' => 'Ulangi ayat',
      'en' => 'Retry ayah',
      'zh' => '重读本节',
      'ja' => '再読',
      _ => 'Retry ayah',
    };
  }

  static String getSetoranRecordAyah(String language) {
    return switch (language) {
      'id' => 'Rekam bacaan',
      'en' => 'Record recitation',
      'zh' => '录音诵读',
      'ja' => '録音する',
      _ => 'Record recitation',
    };
  }

  static String getSetoranStopRecording(String language) {
    return switch (language) {
      'id' => 'Stop rekam',
      'en' => 'Stop recording',
      'zh' => '停止录音',
      'ja' => '録音停止',
      _ => 'Stop recording',
    };
  }

  static String getSetoranPlayRecording(String language) {
    return switch (language) {
      'id' => 'Putar rekaman',
      'en' => 'Play recording',
      'zh' => '播放录音',
      'ja' => '録音を再生',
      _ => 'Play recording',
    };
  }

  static String getSetoranStopPlayback(String language) {
    return switch (language) {
      'id' => 'Stop putar',
      'en' => 'Stop playback',
      'zh' => '停止播放',
      'ja' => '再生停止',
      _ => 'Stop playback',
    };
  }

  static String getSetoranRecordingSaved(String language) {
    return switch (language) {
      'id' => 'Rekaman tersimpan',
      'en' => 'Recording saved',
      'zh' => '录音已保存',
      'ja' => '録音を保存しました',
      _ => 'Recording saved',
    };
  }

  static String getSetoranMicPermissionDenied(String language) {
    return switch (language) {
      'id' => 'Izin mikrofon ditolak — aktifkan di pengaturan perangkat',
      'en' => 'Microphone permission denied — enable it in device settings',
      'zh' => '麦克风权限被拒绝 — 请在设备设置中开启',
      'ja' => 'マイクの許可がありません — 設定で有効にしてください',
      _ => 'Microphone permission denied',
    };
  }

  static String getSetoranRevealAllHint(String language, int done, int total) {
    return switch (language) {
      'id' => 'Ayat jelas: $done / $total — selesaikan semua untuk setoran.',
      'en' => 'Revealed: $done / $total — complete all ayahs to finish setoran.',
      'zh' => '已显示：$done / $total — 完成所有节后标记复习。',
      'ja' => '表示済み：$done / $total — 全節で完了。',
      _ => 'Revealed: $done / $total ayahs.',
    };
  }

  static String getJuzAmmaMemorizedLabel(String language) {
    return switch (language) {
      'id' => 'Ayat dihafal',
      'en' => 'Ayahs memorized',
      'zh' => '已背经文',
      'ja' => '暗誦した節',
      _ => 'Ayahs memorized',
    };
  }

  static String getJuzAmmaMarkMemorized(String language) {
    return switch (language) {
      'id' => 'Tandai dihafal',
      'en' => 'Mark memorized',
      'zh' => '标记已背',
      'ja' => '暗誦済みにする',
      _ => 'Mark memorized',
    };
  }

  static String formatJuzAmmaAyahRef(
    int surah,
    int from,
    int to,
    String language,
  ) {
    final ref = from == to ? '$surah:$from' : '$surah:$from–$to';
    return switch (language) {
      'id' => 'QS. $ref',
      'en' => 'Q. $ref',
      'zh' => '第 $ref 节',
      'ja' => 'クルアーン $ref',
      _ => 'Q. $ref',
    };
  }

  static String getAsmaEmpty(String language) {
    return switch (language) {
      'id' => 'Belum ada entri Asmaul Husna.',
      'en' => 'No Names of Allah entries yet.',
      'zh' => '尚无真主美名条目。',
      'ja' => 'アッラーの美名の項目がありません。',
      _ => 'No Names of Allah entries yet.',
    };
  }

  static String getDuaProphetName(String key, String language) {
    return switch (key) {
      'adam' => switch (language) {
          'id' => 'Nabi Adam',
          'zh' => '先知阿丹',
          'ja' => 'アダム',
          _ => 'Prophet Adam',
        },
      'nuh' => switch (language) {
          'id' => 'Nabi Nuh',
          'zh' => '先知努哈',
          'ja' => 'ヌーフ',
          _ => 'Prophet Nuh',
        },
      'hud' => switch (language) {
          'id' => 'Nabi Hud',
          'zh' => '先知呼德',
          'ja' => 'フード',
          _ => 'Prophet Hud',
        },
      'ibrahim' => switch (language) {
          'id' => 'Nabi Ibrahim',
          'zh' => '先知易卜拉欣',
          'ja' => 'イブラーヒーム',
          _ => 'Prophet Ibrahim',
        },
      'lut' => switch (language) {
          'id' => 'Nabi Lut',
          'zh' => '先知鲁特',
          'ja' => 'ルート',
          _ => 'Prophet Lut',
        },
      'yusuf' => switch (language) {
          'id' => 'Nabi Yusuf',
          'zh' => '先知优素福',
          'ja' => 'ユースフ',
          _ => 'Prophet Yusuf',
        },
      'ayyub' => switch (language) {
          'id' => 'Nabi Ayyub',
          'zh' => '先知艾优卜',
          'ja' => 'アイユーブ',
          _ => 'Prophet Ayyub',
        },
      'syuaib' => switch (language) {
          'id' => 'Nabi Syu\'aib',
          'zh' => '先知舒阿卜',
          'ja' => 'シュアイブ',
          _ => 'Prophet Shu\'ayb',
        },
      'musa' => switch (language) {
          'id' => 'Nabi Musa',
          'zh' => '先知穆萨',
          'ja' => 'ムーサー',
          _ => 'Prophet Musa',
        },
      'sulaiman' => switch (language) {
          'id' => 'Nabi Sulaiman',
          'zh' => '先知苏莱曼',
          'ja' => 'スライマーン',
          _ => 'Prophet Sulaiman',
        },
      'yunus' => switch (language) {
          'id' => 'Nabi Yunus',
          'zh' => '先知优努斯',
          'ja' => 'ユーヌス',
          _ => 'Prophet Yunus',
        },
      'zakaria' => switch (language) {
          'id' => 'Nabi Zakaria',
          'zh' => '先知宰凯里雅',
          'ja' => 'ザカリーヤー',
          _ => 'Prophet Zakariyya',
        },
      'isa' => switch (language) {
          'id' => 'Nabi Isa',
          'zh' => '先知尔萨',
          'ja' => 'イーサー',
          _ => 'Prophet Isa',
        },
      'muhammad' => switch (language) {
          'id' => 'Nabi Muhammad',
          'zh' => '先知穆罕默德',
          'ja' => 'ムハンマド',
          _ => 'Prophet Muhammad',
        },
      _ => key,
    };
  }

  static String getDuaProphetCount(int count, String language) {
    return switch (language) {
      'id' => '$count doa',
      'zh' => '$count 则祈祷',
      'ja' => '祈り $count 件',
      _ => '$count prayers',
    };
  }

  static String formatDuaAyahRef(int surah, int from, int to, String language) {
    final range = from == to ? '$from' : '$from-$to';
    return switch (language) {
      'id' => 'QS $surah:$range',
      'zh' => '第$surah章 $range节',
      'ja' => '第$surah章 $range節',
      _ => 'Surah $surah:$range',
    };
  }

  static String getDuaOpenInReader(String language) {
    return switch (language) {
      'id' => 'Buka di Reader',
      'en' => 'Open in Reader',
      'zh' => '在阅读器中打开',
      'ja' => 'リーダーで開く',
      _ => 'Open in Reader',
    };
  }

  static String getDuaLoadError(String language) {
    return switch (language) {
      'id' => 'Katalog doa tidak dapat dimuat.',
      'en' => 'Could not load the dua catalog.',
      'zh' => '无法加载祈祷目录。',
      'ja' => '祈りの目録を読み込めませんでした。',
      _ => 'Could not load the dua catalog.',
    };
  }

  static String getDuaEmpty(String language) {
    return switch (language) {
      'id' => 'Belum ada doa dalam kategori ini.',
      'en' => 'No duas in this category yet.',
      'zh' => '此类别暂无祈祷。',
      'ja' => 'このカテゴリにはまだ祈りがありません。',
      _ => 'No duas in this category yet.',
    };
  }

  static String getDuaVerseUnavailable(String language) {
    return switch (language) {
      'id' => 'Teks ayat tidak tersedia.',
      'en' => 'Verse text is unavailable.',
      'zh' => '节文不可用。',
      'ja' => '節のテキストを利用できません。',
      _ => 'Verse text is unavailable.',
    };
  }

  /// Get localized text for "Read Juz" button
  static String getReadJuz(String language) {
    return switch (language) {
      'id' => 'Baca Juz',
      'en' => 'Read Juz',
      'zh' => '阅读章节',
      'ja' => 'ジュズを読む',
      _ => 'Read Juz',
    };
  }

  /// Get localized text for "Read Page" button
  static String getReadPage(String language) {
    return switch (language) {
      'id' => 'Baca Halaman',
      'en' => 'Read Page',
      'zh' => '阅读页',
      'ja' => 'ページを読む',
      _ => 'Read Page',
    };
  }

  /// Get localized text for "Last Read"
  static String getLastRead(String language) {
    return switch (language) {
      'id' => 'Terakhir Dibaca',
      'en' => 'Last Read',
      'zh' => '最后阅读',
      'ja' => '最後に読んだ',
      _ => 'Last Read',
    };
  }

  /// Get localized text for "Continue reading"
  static String getContinueReading(String language) {
    return switch (language) {
      'id' => 'Lanjutkan membaca',
      'en' => 'Continue reading',
      'zh' => '继续阅读',
      'ja' => '読み続ける',
      _ => 'Continue reading',
    };
  }

  /// Get localized text for "Page X" format
  static String getPageText(int pageNo, String language) {
    final pageLabel = _getPage(language);
    return '$pageLabel $pageNo';
  }

  /// Get localized text for "Mushaf - Page X" format
  static String getMushafPageText(int pageNo, String language) {
    final mushafLabel = _getMushaf(language);
    final pageLabel = _getPage(language);
    return '$mushafLabel - $pageLabel $pageNo';
  }

  /// Get localized text for AppBar subtitles based on language code
  static String getSubtitleText(String key, String language) {
    return switch (key) {
      'settings_subtitle' => _getSettingsSubtitle(language),
      'read_subtitle' => _getReadSubtitle(language),
      'bookmarks_subtitle' => _getBookmarksSubtitle(language),
      'bookmarks_empty' => _getBookmarksEmpty(language),
      'search_subtitle' => _getSearchSubtitle(language),
      'quick_search_hint' => _getQuickSearchHint(language),
      'quick_search_no_results' => _getQuickSearchNoResults(language),
      'notes_subtitle' => _getNotesSubtitle(language),
      'notes_search_hint' => _getNotesSearchHint(language),
      'notes_empty' => _getNotesEmpty(language),
      'notes_no_results' => _getNotesNoResults(language),
      'highlights_search_hint' => _getHighlightsSearchHint(language),
      'highlights_empty' => _getHighlightsEmpty(language),
      'highlights_no_results' => _getHighlightsNoResults(language),
      'library_subtitle' => _getLibrarySubtitle(language),
      'dua_subtitle' => _getDuaSubtitle(language),
      'library_search_hint' => _getLibrarySearchHint(language),
      'library_no_results' => _getLibraryNoResults(language),
      _ => key,
    };
  }

  static String _getRead(String language) {
    return switch (language) {
      'id' => 'Baca',
      'en' => 'Read',
      'zh' => '阅读',
      'ja' => '読む',
      _ => 'Read',
    };
  }

  static String _getHafalan(String language) {
    return switch (language) {
      'id' => 'Hafalan',
      'en' => 'Memorize',
      'zh' => '背诵',
      'ja' => '暗誦',
      _ => 'Memorize',
    };
  }

  static String _getHafalanNav(String language) {
    return _getHafalan(language);
  }

  static String _getSearch(String language) {
    return switch (language) {
      'id' => 'Cari',
      'en' => 'Search',
      'zh' => '搜索',
      'ja' => '検索',
      _ => 'Search',
    };
  }

  static String _getBookmarks(String language) {
    return switch (language) {
      'id' => 'Penanda',
      'en' => 'Bookmarks',
      'zh' => '书签',
      'ja' => 'ブックマーク',
      _ => 'Bookmarks',
    };
  }

  static String _getSettings(String language) {
    return switch (language) {
      'id' => 'Pengaturan',
      'en' => 'Settings',
      'zh' => '设置',
      'ja' => '設定',
      _ => 'Settings',
    };
  }

  static String _getSurah(String language) {
    // Surah is the same in all languages (it's an Arabic term)
    return 'Surah';
  }

  static String _getJuz(String language) {
    // Juz is the same in all languages (it's an Arabic term)
    return 'Juz';
  }

  static String _getMushaf(String language) {
    // Mushaf is the same in all languages (it's an Arabic term)
    return 'Mushaf';
  }

  static String _getPage(String language) {
    return switch (language) {
      'id' => 'Halaman',
      'en' => 'Page',
      'zh' => '页',
      'ja' => 'ページ',
      _ => 'Page',
    };
  }

  static String _getSettingsSubtitle(String language) {
    return switch (language) {
      'id' => 'Preferensi & tampilan',
      'en' => 'Preferences & display',
      'zh' => '偏好和显示',
      'ja' => '設定と表示',
      _ => 'Preferences & display',
    };
  }

  static String _getReadSubtitle(String language) {
    return switch (language) {
      'id' => 'Baca dan renungkan',
      'en' => 'Read and reflect',
      'zh' => '阅读与思考',
      'ja' => '読んで考える',
      _ => 'Read and reflect',
    };
  }

  static String _getBookmarksSubtitle(String language) {
    return switch (language) {
      'id' => 'Disimpan untuk nanti',
      'en' => 'Saved for later',
      'zh' => '稍后保存',
      'ja' => '後で保存',
      _ => 'Saved for later',
    };
  }

  static String _getBookmarksEmpty(String language) {
    return switch (language) {
      'id' => 'Belum ada bookmark',
      'en' => 'No bookmarks yet',
      'zh' => '还没有书签',
      'ja' => 'ブックマークがまだありません',
      _ => 'No bookmarks yet',
    };
  }

  static String _getSearchSubtitle(String language) {
    return switch (language) {
      'id' => 'Cari di seluruh Al-Qur\'an',
      'en' => 'Search across the Qur\'an',
      'zh' => '搜索古兰经',
      'ja' => 'コーラン全体を検索',
      _ => 'Search across the Qur\'an',
    };
  }

  static String _getQuickSearchHint(String language) {
    return switch (language) {
      'id' => 'Cari Surah, Juz, atau Halaman...',
      'en' => 'Search Surah, Juz, or Page...',
      'zh' => '搜索章节、卷或页...',
      'ja' => 'スーラ、ジュズ、またはページを検索...',
      _ => 'Search Surah, Juz, or Page...',
    };
  }

  static String _getQuickSearchNoResults(String language) {
    return switch (language) {
      'id' => 'Tidak ada hasil ditemukan',
      'en' => 'No results found',
      'zh' => '未找到结果',
      'ja' => '結果が見つかりません',
      _ => 'No results found',
    };
  }

  /// Get localized text for search screen content
  static String getSearchText(String key, String language) {
    return switch (key) {
      'search_placeholder' => _getSearchPlaceholder(language),
      'search_title' => _getSearchTitle(language),
      'search_by_label' => _getSearchByLabel(language),
      'surah_example' => _getSurahExample(language),
      'juz_example' => _getJuzExample(language),
      'page_example' => _getPageExample(language),
      'verse_example' => _getVerseExample(language),
      'verse_label' => _getVerseLabel(language),
      'translation_example' => _getTranslationExample(language),
      'translation_label' => _getTranslationLabel(language),
      'no_results' => _getNoResults(language),
      'results_heading' => _getResultsHeading(language),
      _ => key,
    };
  }

  static String _getResultsHeading(String language) {
    return switch (language) {
      'id' => 'Hasil',
      'en' => 'Results',
      'zh' => '结果',
      'ja' => '検索結果',
      _ => 'Results',
    };
  }

  static String _getSearchPlaceholder(String language) {
    return switch (language) {
      'id' => 'Surah, Juz, Halaman, Ayat (2:255), atau terjemahan...',
      'en' => 'Surah, Juz, Page, Verse (2:255), or translation...',
      'zh' => '章节、卷、页、经文 (2:255) 或翻译...',
      'ja' => '章、ジュズ、ページ、節 (2:255) または翻訳...',
      _ => 'Surah, Juz, Page, Verse (2:255), or translation...',
    };
  }

  static String _getSearchTitle(String language) {
    return switch (language) {
      'id' => 'Cari Al-Qur\'an',
      'en' => 'Search the Qur\'an',
      'zh' => '搜索古兰经',
      'ja' => 'コーランを検索',
      _ => 'Search the Qur\'an',
    };
  }

  static String _getSearchByLabel(String language) {
    return switch (language) {
      'id' => 'Anda dapat mencari berdasarkan:',
      'en' => 'You can search by:',
      'zh' => '您可以按以下方式搜索：',
      'ja' => '次の方法で検索できます：',
      _ => 'You can search by:',
    };
  }

  static String _getSurahExample(String language) {
    return switch (language) {
      'id' => 'Al-Fatihah, Al-Baqarah, dll.',
      'en' => 'Al-Fatihah, Al-Baqarah, etc.',
      'zh' => '开端章、黄牛章等',
      'ja' => 'アル・ファーティハ、アル・バカラなど',
      _ => 'Al-Fatihah, Al-Baqarah, etc.',
    };
  }

  static String _getJuzExample(String language) {
    final juzLabel = _getJuz(language);
    return switch (language) {
      'id' => '$juzLabel 1, $juzLabel 2, dll.',
      'en' => '$juzLabel 1, $juzLabel 2, etc.',
      'zh' => '$juzLabel 1、$juzLabel 2 等',
      'ja' => '$juzLabel 1、$juzLabel 2 など',
      _ => '$juzLabel 1, $juzLabel 2, etc.',
    };
  }

  static String _getPageExample(String language) {
    final pageLabel = _getPage(language);
    return switch (language) {
      'id' => '$pageLabel 604, $pageLabel 1, dll.',
      'en' => '$pageLabel 604, $pageLabel 1, etc.',
      'zh' => '$pageLabel 604、$pageLabel 1 等',
      'ja' => '$pageLabel 604、$pageLabel 1 など',
      _ => '$pageLabel 604, $pageLabel 1, etc.',
    };
  }

  static String _getVerseExample(String language) {
    return switch (language) {
      'id' => '2:255, 3:190, dll.',
      'en' => '2:255, 3:190, etc.',
      'zh' => '2:255、3:190 等',
      'ja' => '2:255、3:190 など',
      _ => '2:255, 3:190, etc.',
    };
  }

  static String _getTranslationExample(String language) {
    return switch (language) {
      'id' => 'Kata apa pun dalam teks terjemahan',
      'en' => 'Any word in translation text',
      'zh' => '翻译文本中的任何单词',
      'ja' => '翻訳テキスト内の任意の単語',
      _ => 'Any word in translation text',
    };
  }

  static String _getVerseLabel(String language) {
    return switch (language) {
      'id' => 'Ayat',
      'en' => 'Verse',
      'zh' => '经文',
      'ja' => '節',
      _ => 'Verse',
    };
  }

  static String _getTranslationLabel(String language) {
    return switch (language) {
      'id' => 'Terjemahan',
      'en' => 'Translation',
      'zh' => '翻译',
      'ja' => '翻訳',
      _ => 'Translation',
    };
  }

  static String _getNoResults(String language) {
    return switch (language) {
      'id' => 'Tidak ada hasil ditemukan',
      'en' => 'No results found',
      'zh' => '未找到结果',
      'ja' => '結果が見つかりません',
      _ => 'No results found',
    };
  }

  /// Get localized text for settings screen
  static String getSettingsText(String key, String language) {
    return switch (key) {
      'settings_title' => _getSettingsTitle(language),
      'quran_settings_header' => _getQuranSettingsHeader(language),
      'translation_language_title' => _getTranslationLanguageTitle(language),
      'translation_language_subtitle' => _getTranslationLanguageSubtitle(language),
      'show_transliteration_title' => _getShowTransliterationTitle(language),
      'show_transliteration_subtitle' => _getShowTransliterationSubtitle(language),
      'show_translation_title' => _getShowTranslationTitle(language),
      'show_translation_subtitle' => _getShowTranslationSubtitle(language),
      'show_tajweed_title' => _getShowTajweedTitle(language),
      'show_tajweed_subtitle' => _getShowTajweedSubtitle(language),
      'app_settings_header' => _getAppSettingsHeader(language),
      'app_language_title' => _getAppLanguageTitle(language),
      'app_language_subtitle' => _getAppLanguageSubtitle(language),
      'theme_title' => _getThemeTitle(language),
      'theme_subtitle' => _getThemeSubtitle(language),
      'language_indonesian_desc' => _getLanguageIndonesianDesc(language),
      'language_english_desc' => _getLanguageEnglishDesc(language),
      'language_chinese_desc' => _getLanguageChineseDesc(language),
      'language_japanese_desc' => _getLanguageJapaneseDesc(language),
      'app_language_indonesian_desc' => _getAppLanguageIndonesianDesc(language),
      'app_language_english_desc' => _getAppLanguageEnglishDesc(language),
      'app_language_chinese_desc' => _getAppLanguageChineseDesc(language),
      'app_language_japanese_desc' => _getAppLanguageJapaneseDesc(language),
      'theme_system_desc' => _getThemeSystemDesc(language),
      'theme_light_desc' => _getThemeLightDesc(language),
      'theme_dark_desc' => _getThemeDarkDesc(language),
      'about_header' => _getAboutHeader(language),
      'version_title' => _getVersionTitle(language),
      'support_title' => _getSupportTitle(language),
      'support_subtitle' => _getSupportSubtitle(language),
      'privacy_title' => _getPrivacyTitle(language),
      'privacy_subtitle' => _getPrivacySubtitle(language),
      'terms_title' => _getTermsTitle(language),
      'terms_subtitle' => _getTermsSubtitle(language),
      'select_theme_dialog' => _getSelectThemeDialog(language),
      'theme_system' => _getThemeSystem(language),
      'theme_light' => _getThemeLight(language),
      'theme_dark' => _getThemeDark(language),
      'support_dialog_title' => _getSupportDialogTitle(language),
      'support_dialog_content' => _getSupportDialogContent(language),
      'tajweed_guide_title' => _getTajweedGuideTitle(language),
      'tajweed_guide_intro' => _getTajweedGuideIntro(language),
      'tajweed_guide_closing' => _getTajweedGuideClosing(language),
      'tajweed_guide_got_it' => _getTajweedGuideGotIt(language),
      'tajweed_rule_ikhfa' => _getTajweedRuleIkhfa(language),
      'tajweed_rule_ikhfa_desc' => _getTajweedRuleIkhfaDesc(language),
      'tajweed_rule_idgham' => _getTajweedRuleIdgham(language),
      'tajweed_rule_idgham_desc' => _getTajweedRuleIdghamDesc(language),
      'tajweed_rule_iqlab' => _getTajweedRuleIqlab(language),
      'tajweed_rule_iqlab_desc' => _getTajweedRuleIqlabDesc(language),
      'tajweed_rule_ghunnah' => _getTajweedRuleGhunnah(language),
      'tajweed_rule_ghunnah_desc' => _getTajweedRuleGhunnahDesc(language),
      'tajweed_rule_qalqalah' => _getTajweedRuleQalqalah(language),
      'tajweed_rule_qalqalah_desc' => _getTajweedRuleQalqalahDesc(language),
      'tajweed_rule_laam_shamsiyah' => _getTajweedRuleLaamShamsiyah(language),
      'tajweed_rule_laam_shamsiyah_desc' => _getTajweedRuleLaamShamsiyahDesc(language),
      'tajweed_rule_madd' => _getTajweedRuleMadd(language),
      'tajweed_rule_madd_desc' => _getTajweedRuleMaddDesc(language),
      'tajweed_rule_ham_wasl' => _getTajweedRuleHamWasl(language),
      'tajweed_rule_ham_wasl_desc' => _getTajweedRuleHamWaslDesc(language),
      // Highlight Guide
      'highlight_guide_title' => _getHighlightGuideTitle(language),
      'highlight_guide_intro' => _getHighlightGuideIntro(language),
      'highlight_guide_closing' => _getHighlightGuideClosing(language),
      'highlight_guide_got_it' => _getHighlightGuideGotIt(language),
      'highlight_color_yellow' => _getHighlightColorYellow(language),
      'highlight_color_yellow_desc' => _getHighlightColorYellowDesc(language),
      'highlight_color_orange' => _getHighlightColorOrange(language),
      'highlight_color_orange_desc' => _getHighlightColorOrangeDesc(language),
      'highlight_color_pink' => _getHighlightColorPink(language),
      'highlight_color_pink_desc' => _getHighlightColorPinkDesc(language),
      'highlight_color_red' => _getHighlightColorRed(language),
      'highlight_color_red_desc' => _getHighlightColorRedDesc(language),
      'highlight_color_purple' => _getHighlightColorPurple(language),
      'highlight_color_purple_desc' => _getHighlightColorPurpleDesc(language),
      'highlight_color_blue' => _getHighlightColorBlue(language),
      'highlight_color_blue_desc' => _getHighlightColorBlueDesc(language),
      'highlight_color_cyan' => _getHighlightColorCyan(language),
      'highlight_color_cyan_desc' => _getHighlightColorCyanDesc(language),
      'highlight_color_green' => _getHighlightColorGreen(language),
      'highlight_color_green_desc' => _getHighlightColorGreenDesc(language),
      'highlight_color_teal' => _getHighlightColorTeal(language),
      'highlight_color_teal_desc' => _getHighlightColorTealDesc(language),
      'highlight_color_other' => _getHighlightColorOther(language),
      'highlight_color_other_desc' => _getHighlightColorOtherDesc(language),
      'selected' => _getSelected(language),
      // Notes & Highlights
      'note_title' => _getNoteTitle(language),
      'note_hint' => _getNoteHint(language),
      'delete_note_title' => _getDeleteNoteTitle(language),
      'delete_note_message' => _getDeleteNoteMessage(language),
      'highlight_title' => _getHighlightTitle(language),
      'remove_highlight' => _getRemoveHighlight(language),
      'save' => _getSave(language),
      'cancel' => _getCancel(language),
      'delete' => _getDelete(language),
      // Bookmark Organization
      'bookmark_folder' => _getBookmarkFolder(language),
      'bookmark_tag' => _getBookmarkTag(language),
      'bookmark_color' => _getBookmarkColor(language),
      'bookmark_note' => _getBookmarkNote(language),
      'bookmark_organize' => _getBookmarkOrganize(language),
      'sort_by' => _getSortBy(language),
      'filter_by' => _getFilterBy(language),
      'sort_date' => _getSortDate(language),
      'sort_surah' => _getSortSurah(language),
      'sort_category' => _getSortCategory(language),
      'filter_all' => _getFilterAll(language),
      'filter_folder' => _getFilterFolder(language),
      'filter_tag' => _getFilterTag(language),
      // Text Settings Dialog
      'text_settings_title' => _getTextSettingsTitle(language),
      'text_settings_arabic_size' => _getTextSettingsArabicSize(language),
      'text_settings_translation_size' => _getTextSettingsTranslationSize(language),
      'text_settings_size_label' => _getTextSettingsSizeLabel(language),
      'text_settings_tajweed_subtitle' => _getTextSettingsTajweedSubtitle(language),
      'apply' => _getApply(language),
      'transliteration_style_title' => _getTransliterationStyleTitle(language),
      'transliteration_style_original' => _getTransliterationStyleOriginal(language),
      'transliteration_style_readable' => _getTransliterationStyleReadable(language),
      'transliteration_source_title' => _getTransliterationSourceTitle(language),
      'transliteration_source_tajweed' => _getTransliterationSourceTajweed(language),
      'transliteration_source_original' => _getTransliterationSourceOriginal(language),
      'transliteration_choice_title' => _getTransliterationChoiceTitle(language),
      'transliteration_style_raw' => _getTransliterationStyleRaw(language),
      'language_name_indonesian' => _getLanguageNameIndonesian(language),
      'language_name_english' => _getLanguageNameEnglish(language),
      'language_name_chinese' => _getLanguageNameChinese(language),
      'language_name_japanese' => _getLanguageNameJapanese(language),
      _ => key,
    };
  }

  static String _getSettingsTitle(String language) {
    return switch (language) {
      'id' => 'Pengaturan',
      'en' => 'Settings',
      'zh' => '设置',
      'ja' => '設定',
      _ => 'Settings',
    };
  }

  static String _getQuranSettingsHeader(String language) {
    return switch (language) {
      'id' => 'Pengaturan Al-Qur\'an',
      'en' => 'Qur\'an Settings',
      'zh' => '古兰经设置',
      'ja' => 'コーラン設定',
      _ => 'Qur\'an Settings',
    };
  }

  static String _getTranslationLanguageTitle(String language) {
    return switch (language) {
      'id' => 'Bahasa Terjemahan',
      'en' => 'Translation Language',
      'zh' => '翻译语言',
      'ja' => '翻訳言語',
      _ => 'Translation Language',
    };
  }

  static String _getTranslationLanguageSubtitle(String language) {
    return switch (language) {
      'id' => 'Bahasa yang digunakan untuk teks terjemahan Al-Qur\'an.',
      'en' => 'Language used for Qur\'an translation text.',
      'zh' => '用于古兰经翻译文本的语言。',
      'ja' => 'コーラン翻訳テキストに使用される言語。',
      _ => 'Language used for Qur\'an translation text.',
    };
  }

  static String _getShowTransliterationTitle(String language) {
    return switch (language) {
      'id' => 'Tampilkan Transliterasi',
      'en' => 'Show Transliteration',
      'zh' => '显示音译',
      'ja' => '音訳を表示',
      _ => 'Show Transliteration',
    };
  }

  static String _getShowTransliterationSubtitle(String language) {
    return switch (language) {
      'id' => 'Tampilkan transliterasi Latin di bawah ayat Arab.',
      'en' => 'Show Latin transliteration under Arabic verses.',
      'zh' => '在阿拉伯经文下方显示拉丁音译。',
      'ja' => 'アラビア語の節の下にラテン音訳を表示。',
      _ => 'Show Latin transliteration under Arabic verses.',
    };
  }

  static String _getShowTranslationTitle(String language) {
    return switch (language) {
      'id' => 'Tampilkan Terjemahan',
      'en' => 'Show Translation',
      'zh' => '显示翻译',
      'ja' => '翻訳を表示',
      _ => 'Show Translation',
    };
  }

  static String _getShowTranslationSubtitle(String language) {
    return switch (language) {
      'id' => 'Tampilkan terjemahan untuk setiap ayat',
      'en' => 'Show translation for each verse',
      'zh' => '显示每节经文的翻译',
      'ja' => '各節の翻訳を表示',
      _ => 'Show translation for each verse',
    };
  }

  static String _getShowTajweedTitle(String language) {
    return switch (language) {
      'id' => 'Tampilkan Tajweed',
      'en' => 'Show Tajweed',
      'zh' => '显示泰吉维德',
      'ja' => 'タジウィードを表示',
      _ => 'Show Tajweed',
    };
  }

  static String _getShowTajweedSubtitle(String language) {
    return switch (language) {
      'id' => 'Tampilkan aturan tajweed dengan kode warna untuk pelafalan yang benar.',
      'en' => 'Color-coded tajweed rules for proper recitation.',
      'zh' => '彩色编码的泰吉维德规则，用于正确诵读。',
      'ja' => '正しい朗読のための色分けされたタジウィード規則。',
      _ => 'Color-coded tajweed rules for proper recitation.',
    };
  }

  static String _getAppSettingsHeader(String language) {
    return switch (language) {
      'id' => 'Pengaturan Aplikasi',
      'en' => 'App Settings',
      'zh' => '应用设置',
      'ja' => 'アプリ設定',
      _ => 'App Settings',
    };
  }

  static String _getAppLanguageTitle(String language) {
    return switch (language) {
      'id' => 'Bahasa Aplikasi',
      'en' => 'App Language',
      'zh' => '应用语言',
      'ja' => 'アプリ言語',
      _ => 'App Language',
    };
  }

  static String _getAppLanguageSubtitle(String language) {
    return switch (language) {
      'id' => 'Bahasa untuk menu dan antarmuka aplikasi.',
      'en' => 'Language for menus and app interface.',
      'zh' => '菜单和应用界面的语言。',
      'ja' => 'メニューとアプリインターフェースの言語。',
      _ => 'Language for menus and app interface.',
    };
  }

  static String _getThemeTitle(String language) {
    return switch (language) {
      'id' => 'Tema',
      'en' => 'Theme',
      'zh' => '主题',
      'ja' => 'テーマ',
      _ => 'Theme',
    };
  }

  static String _getThemeSubtitle(String language) {
    return switch (language) {
      'id' => 'Pilih Terang, Gelap, atau default Sistem.',
      'en' => 'Choose Light, Dark, or System default.',
      'zh' => '选择浅色、深色或系统默认。',
      'ja' => 'ライト、ダーク、またはシステムデフォルトを選択。',
      _ => 'Choose Light, Dark, or System default.',
    };
  }

  // Language option descriptions
  static String _getLanguageIndonesianDesc(String language) {
    return switch (language) {
      'id' => 'Terjemahan dalam bahasa Indonesia',
      'en' => 'Translation in Indonesian',
      'zh' => '印尼语翻译',
      'ja' => 'インドネシア語の翻訳',
      _ => 'Translation in Indonesian',
    };
  }

  static String _getLanguageEnglishDesc(String language) {
    return switch (language) {
      'id' => 'Terjemahan dalam bahasa Inggris',
      'en' => 'Translation in English',
      'zh' => '英语翻译',
      'ja' => '英語の翻訳',
      _ => 'Translation in English',
    };
  }

  static String _getLanguageChineseDesc(String language) {
    return switch (language) {
      'id' => 'Terjemahan dalam bahasa Mandarin',
      'en' => 'Translation in Chinese',
      'zh' => '中文翻译',
      'ja' => '中国語の翻訳',
      _ => 'Translation in Chinese',
    };
  }

  static String _getLanguageJapaneseDesc(String language) {
    return switch (language) {
      'id' => 'Terjemahan dalam bahasa Jepang',
      'en' => 'Translation in Japanese',
      'zh' => '日语翻译',
      'ja' => '日本語の翻訳',
      _ => 'Translation in Japanese',
    };
  }

  // App language option descriptions (different from translation language)
  static String _getAppLanguageIndonesianDesc(String language) {
    return switch (language) {
      'id' => 'Menu dan antarmuka dalam bahasa Indonesia',
      'en' => 'Menu and interface in Indonesian',
      'zh' => '菜单和界面使用印尼语',
      'ja' => 'メニューとインターフェースはインドネシア語',
      _ => 'Menu and interface in Indonesian',
    };
  }

  static String _getAppLanguageEnglishDesc(String language) {
    return switch (language) {
      'id' => 'Menu dan antarmuka dalam bahasa Inggris',
      'en' => 'Menu and interface in English',
      'zh' => '菜单和界面使用英语',
      'ja' => 'メニューとインターフェースは英語',
      _ => 'Menu and interface in English',
    };
  }

  static String _getAppLanguageChineseDesc(String language) {
    return switch (language) {
      'id' => 'Menu dan antarmuka dalam bahasa Mandarin',
      'en' => 'Menu and interface in Chinese',
      'zh' => '菜单和界面使用中文',
      'ja' => 'メニューとインターフェースは中国語',
      _ => 'Menu and interface in Chinese',
    };
  }

  static String _getAppLanguageJapaneseDesc(String language) {
    return switch (language) {
      'id' => 'Menu dan antarmuka dalam bahasa Jepang',
      'en' => 'Menu and interface in Japanese',
      'zh' => '菜单和界面使用日语',
      'ja' => 'メニューとインターフェースは日本語',
      _ => 'Menu and interface in Japanese',
    };
  }

  // Theme option descriptions
  static String _getThemeSystemDesc(String language) {
    return switch (language) {
      'id' => 'Mengikuti pengaturan tema sistem perangkat',
      'en' => 'Follow device system theme settings',
      'zh' => '跟随设备系统主题设置',
      'ja' => 'デバイスのシステムテーマ設定に従う',
      _ => 'Follow device system theme settings',
    };
  }

  static String _getThemeLightDesc(String language) {
    return switch (language) {
      'id' => 'Tema terang untuk penggunaan di siang hari',
      'en' => 'Light theme for daytime use',
      'zh' => '浅色主题，适合白天使用',
      'ja' => '昼間の使用に適したライトテーマ',
      _ => 'Light theme for daytime use',
    };
  }

  static String _getThemeDarkDesc(String language) {
    return switch (language) {
      'id' => 'Tema gelap untuk penggunaan di malam hari',
      'en' => 'Dark theme for nighttime use',
      'zh' => '深色主题，适合夜间使用',
      'ja' => '夜間の使用に適したダークテーマ',
      _ => 'Dark theme for nighttime use',
    };
  }

  static String _getAboutHeader(String language) {
    return switch (language) {
      'id' => 'Tentang',
      'en' => 'About',
      'zh' => '关于',
      'ja' => 'について',
      _ => 'About',
    };
  }

  static String _getVersionTitle(String language) {
    return switch (language) {
      'id' => 'Versi aplikasi',
      'en' => 'Version',
      'zh' => '版本',
      'ja' => 'バージョン',
      _ => 'Version',
    };
  }

  static String _getSupportTitle(String language) {
    return switch (language) {
      'id' => 'Dukung pengembang',
      'en' => 'Support the developer',
      'zh' => '支持开发者',
      'ja' => '開発者をサポート',
      _ => 'Support the developer',
    };
  }

  static String _getSupportSubtitle(String language) {
    return switch (language) {
      'id' => 'Donasi opsional melalui Buy Me a Coffee',
      'en' => 'Optional donation via Buy Me a Coffee',
      'zh' => '通过 Buy Me a Coffee 进行可选捐赠',
      'ja' => 'Buy Me a Coffee 経由の任意の寄付',
      _ => 'Optional donation via Buy Me a Coffee',
    };
  }

  static String _getPrivacyTitle(String language) {
    return switch (language) {
      'id' => 'Kebijakan Privasi',
      'en' => 'Privacy Policy',
      'zh' => '隐私政策',
      'ja' => 'プライバシーポリシー',
      _ => 'Privacy Policy',
    };
  }

  static String _getPrivacySubtitle(String language) {
    return switch (language) {
      'id' => 'Baca bagaimana kami menangani privasi (tanpa iklan, tanpa pelacakan).',
      'en' => 'Read how we handle privacy (no ads, no tracking).',
      'zh' => '阅读我们如何处理隐私（无广告，无跟踪）。',
      'ja' => 'プライバシーの処理方法を読む（広告なし、追跡なし）。',
      _ => 'Read how we handle privacy (no ads, no tracking).',
    };
  }

  static String _getTermsTitle(String language) {
    return switch (language) {
      'id' => 'Ketentuan Layanan',
      'en' => 'Terms of Service',
      'zh' => '服务条款',
      'ja' => '利用規約',
      _ => 'Terms of Service',
    };
  }

  static String _getTermsSubtitle(String language) {
    return switch (language) {
      'id' => 'Tinjau ketentuan untuk menggunakan aplikasi.',
      'en' => 'Review the terms for using the app.',
      'zh' => '查看使用应用的条款。',
      'ja' => 'アプリを使用するための条件を確認。',
      _ => 'Review the terms for using the app.',
    };
  }

  static String _getSelectThemeDialog(String language) {
    return switch (language) {
      'id' => 'Pilih Tema',
      'en' => 'Select Theme',
      'zh' => '选择主题',
      'ja' => 'テーマを選択',
      _ => 'Select Theme',
    };
  }

  static String _getThemeSystem(String language) {
    return switch (language) {
      'id' => 'Sistem',
      'en' => 'System',
      'zh' => '系统',
      'ja' => 'システム',
      _ => 'System',
    };
  }

  static String _getThemeLight(String language) {
    return switch (language) {
      'id' => 'Terang',
      'en' => 'Light',
      'zh' => '浅色',
      'ja' => 'ライト',
      _ => 'Light',
    };
  }

  static String _getThemeDark(String language) {
    return switch (language) {
      'id' => 'Gelap',
      'en' => 'Dark',
      'zh' => '深色',
      'ja' => 'ダーク',
      _ => 'Dark',
    };
  }

  static String _getSupportDialogTitle(String language) {
    return switch (language) {
      'id' => 'Dukung pengembang',
      'en' => 'Support the developer',
      'zh' => '支持开发者',
      'ja' => '開発者をサポート',
      _ => 'Support the developer',
    };
  }

  static String _getSupportDialogContent(String language) {
    return switch (language) {
      'id' => 'Ini adalah donasi eksternal opsional dan tidak membuka fitur.',
      'en' => 'This is an optional external donation and does not unlock features.',
      'zh' => '这是可选的外部捐赠，不会解锁功能。',
      'ja' => 'これはオプションの外部寄付であり、機能のロックを解除しません。',
      _ => 'This is an optional external donation and does not unlock features.',
    };
  }

  // Tajweed Guide Localizations
  static String _getTajweedGuideTitle(String language) {
    return switch (language) {
      'id' => 'Panduan Warna Tajweed',
      'en' => 'Tajweed Color Guide',
      'zh' => '泰吉维德颜色指南',
      'ja' => 'タジウィードカラーガイド',
      _ => 'Tajweed Color Guide',
    };
  }

  static String _getTajweedGuideIntro(String language) {
    return switch (language) {
      'id' => 'Warna berikut menunjukkan aturan tajweed yang berbeda:',
      'en' => 'The following colors indicate different tajweed rules:',
      'zh' => '以下颜色表示不同的泰吉维德规则：',
      'ja' => '次の色は異なるタジウィード規則を示しています：',
      _ => 'The following colors indicate different tajweed rules:',
    };
  }

  static String _getTajweedGuideClosing(String language) {
    return switch (language) {
      'id' => 'Warna-warna ini membantu Anda mengidentifikasi dan menerapkan aturan tajweed yang benar saat membaca.',
      'en' => 'These colors help you identify and apply proper tajweed rules while reciting.',
      'zh' => '这些颜色帮助您在诵读时识别和应用正确的泰吉维德规则。',
      'ja' => 'これらの色は、朗読中に適切なタジウィード規則を識別して適用するのに役立ちます。',
      _ => 'These colors help you identify and apply proper tajweed rules while reciting.',
    };
  }

  static String _getTajweedGuideGotIt(String language) {
    return switch (language) {
      'id' => 'Mengerti',
      'en' => 'Got it',
      'zh' => '知道了',
      'ja' => '了解しました',
      _ => 'Got it',
    };
  }

  // Tajweed Rule Names
  static String _getTajweedRuleIkhfa(String language) {
    return 'Ikhfa'; // Arabic term, same in all languages
  }

  static String _getTajweedRuleIkhfaDesc(String language) {
    return switch (language) {
      'id' => 'Penyembunyian',
      'en' => 'Concealment',
      'zh' => '隐藏',
      'ja' => '隠蔽',
      _ => 'Concealment',
    };
  }

  static String _getTajweedRuleIdgham(String language) {
    return 'Idgham'; // Arabic term
  }

  static String _getTajweedRuleIdghamDesc(String language) {
    return switch (language) {
      'id' => 'Penggabungan',
      'en' => 'Merging',
      'zh' => '合并',
      'ja' => '統合',
      _ => 'Merging',
    };
  }

  static String _getTajweedRuleIqlab(String language) {
    return 'Iqlab'; // Arabic term
  }

  static String _getTajweedRuleIqlabDesc(String language) {
    return switch (language) {
      'id' => 'Konversi',
      'en' => 'Conversion',
      'zh' => '转换',
      'ja' => '変換',
      _ => 'Conversion',
    };
  }

  static String _getTajweedRuleGhunnah(String language) {
    return 'Ghunnah'; // Arabic term
  }

  static String _getTajweedRuleGhunnahDesc(String language) {
    return switch (language) {
      'id' => 'Nasalisasi',
      'en' => 'Nasalization',
      'zh' => '鼻音化',
      'ja' => '鼻音化',
      _ => 'Nasalization',
    };
  }

  static String _getTajweedRuleQalqalah(String language) {
    return 'Qalqalah'; // Arabic term
  }

  static String _getTajweedRuleQalqalahDesc(String language) {
    return switch (language) {
      'id' => 'Gema',
      'en' => 'Echo',
      'zh' => '回声',
      'ja' => 'エコー',
      _ => 'Echo',
    };
  }

  static String _getTajweedRuleLaamShamsiyah(String language) {
    return switch (language) {
      'id' => 'Laam Syamsiyah',
      'en' => 'Laam Shamsiyah',
      'zh' => '太阳拉姆',
      'ja' => 'ラーム・シャムスィーヤ',
      _ => 'Laam Shamsiyah',
    };
  }

  static String _getTajweedRuleLaamShamsiyahDesc(String language) {
    return switch (language) {
      'id' => 'Lam Matahari',
      'en' => 'Solar Lam',
      'zh' => '太阳拉姆',
      'ja' => '太陽のラーム',
      _ => 'Solar Lam',
    };
  }

  static String _getTajweedRuleMadd(String language) {
    return 'Madd'; // Arabic term
  }

  static String _getTajweedRuleMaddDesc(String language) {
    return switch (language) {
      'id' => 'Pemanjangan',
      'en' => 'Elongation',
      'zh' => '延长',
      'ja' => '延長',
      _ => 'Elongation',
    };
  }

  static String _getTajweedRuleHamWasl(String language) {
    return switch (language) {
      'id' => 'Ham Wasl',
      'en' => 'Ham Wasl',
      'zh' => '连接哈姆扎',
      'ja' => 'ハム・ワスル',
      _ => 'Ham Wasl',
    };
  }

  static String _getTajweedRuleHamWaslDesc(String language) {
    return switch (language) {
      'id' => 'Hamzah Penyambung',
      'en' => 'Connecting Hamza',
      'zh' => '连接哈姆扎',
      'ja' => '接続ハムザ',
      _ => 'Connecting Hamza',
    };
  }

  // Notes & Highlights Localizations
  static String _getNoteTitle(String language) {
    return switch (language) {
      'id' => 'Catatan',
      'en' => 'Note',
      'zh' => '笔记',
      'ja' => 'ノート',
      _ => 'Note',
    };
  }

  static String _getNoteHint(String language) {
    return switch (language) {
      'id' => 'Tulis catatan untuk ayat ini...',
      'en' => 'Write a note for this verse...',
      'zh' => '为这节经文写笔记...',
      'ja' => 'この節のノートを書く...',
      _ => 'Write a note for this verse...',
    };
  }

  static String _getDeleteNoteTitle(String language) {
    return switch (language) {
      'id' => 'Hapus catatan?',
      'en' => 'Delete note?',
      'zh' => '删除笔记？',
      'ja' => 'ノートを削除しますか？',
      _ => 'Delete note?',
    };
  }

  static String _getDeleteNoteMessage(String language) {
    return switch (language) {
      'id' => 'Catatan ini akan dihapus secara permanen.',
      'en' => 'This note will be permanently deleted.',
      'zh' => '此笔记将被永久删除。',
      'ja' => 'このノートは完全に削除されます。',
      _ => 'This note will be permanently deleted.',
    };
  }

  static String _getHighlightTitle(String language) {
    return switch (language) {
      'id' => 'Pilih Warna Highlight',
      'en' => 'Select Highlight Color',
      'zh' => '选择高亮颜色',
      'ja' => 'ハイライト色を選択',
      _ => 'Select Highlight Color',
    };
  }

  static String _getRemoveHighlight(String language) {
    return switch (language) {
      'id' => 'Hapus Highlight',
      'en' => 'Remove Highlight',
      'zh' => '移除高亮',
      'ja' => 'ハイライトを削除',
      _ => 'Remove Highlight',
    };
  }

  static String _getSave(String language) {
    return switch (language) {
      'id' => 'Simpan',
      'en' => 'Save',
      'zh' => '保存',
      'ja' => '保存',
      _ => 'Save',
    };
  }

  static String _getCancel(String language) {
    return switch (language) {
      'id' => 'Batal',
      'en' => 'Cancel',
      'zh' => '取消',
      'ja' => 'キャンセル',
      _ => 'Cancel',
    };
  }

  static String _getDelete(String language) {
    return switch (language) {
      'id' => 'Hapus',
      'en' => 'Delete',
      'zh' => '删除',
      'ja' => '削除',
      _ => 'Delete',
    };
  }

  // Bookmark Organization Localizations
  static String _getBookmarkFolder(String language) {
    return switch (language) {
      'id' => 'Folder',
      'en' => 'Folder',
      'zh' => '文件夹',
      'ja' => 'フォルダ',
      _ => 'Folder',
    };
  }

  static String _getBookmarkTag(String language) {
    return switch (language) {
      'id' => 'Tag',
      'en' => 'Tag',
      'zh' => '标签',
      'ja' => 'タグ',
      _ => 'Tag',
    };
  }

  static String _getBookmarkColor(String language) {
    return switch (language) {
      'id' => 'Warna',
      'en' => 'Color',
      'zh' => '颜色',
      'ja' => '色',
      _ => 'Color',
    };
  }

  static String _getBookmarkNote(String language) {
    return switch (language) {
      'id' => 'Catatan',
      'en' => 'Note',
      'zh' => '笔记',
      'ja' => 'ノート',
      _ => 'Note',
    };
  }

  static String _getBookmarkOrganize(String language) {
    return switch (language) {
      'id' => 'Organisir Bookmark',
      'en' => 'Organize Bookmark',
      'zh' => '整理书签',
      'ja' => 'ブックマークを整理',
      _ => 'Organize Bookmark',
    };
  }

  static String _getSortBy(String language) {
    return switch (language) {
      'id' => 'Urutkan berdasarkan',
      'en' => 'Sort by',
      'zh' => '排序方式',
      'ja' => '並び替え',
      _ => 'Sort by',
    };
  }

  static String _getFilterBy(String language) {
    return switch (language) {
      'id' => 'Filter berdasarkan',
      'en' => 'Filter by',
      'zh' => '筛选方式',
      'ja' => 'フィルター',
      _ => 'Filter by',
    };
  }

  static String _getSortDate(String language) {
    return switch (language) {
      'id' => 'Tanggal',
      'en' => 'Date',
      'zh' => '日期',
      'ja' => '日付',
      _ => 'Date',
    };
  }

  static String _getSortSurah(String language) {
    return switch (language) {
      'id' => 'Surah',
      'en' => 'Surah',
      'zh' => '章节',
      'ja' => 'スーラ',
      _ => 'Surah',
    };
  }

  static String _getSortCategory(String language) {
    return switch (language) {
      'id' => 'Kategori',
      'en' => 'Category',
      'zh' => '类别',
      'ja' => 'カテゴリ',
      _ => 'Category',
    };
  }

  static String _getFilterAll(String language) {
    return switch (language) {
      'id' => 'Semua',
      'en' => 'All',
      'zh' => '全部',
      'ja' => 'すべて',
      _ => 'All',
    };
  }

  static String _getFilterFolder(String language) {
    return switch (language) {
      'id' => 'Folder',
      'en' => 'Folder',
      'zh' => '文件夹',
      'ja' => 'フォルダ',
      _ => 'Folder',
    };
  }

  static String _getFilterTag(String language) {
    return switch (language) {
      'id' => 'Tag',
      'en' => 'Tag',
      'zh' => '标签',
      'ja' => 'タグ',
      _ => 'Tag',
    };
  }

  // Text Settings Dialog Localizations
  static String _getTextSettingsTitle(String language) {
    return switch (language) {
      'id' => 'Pengaturan Teks',
      'en' => 'Text Settings',
      'zh' => '文本设置',
      'ja' => 'テキスト設定',
      _ => 'Text Settings',
    };
  }

  static String _getTextSettingsArabicSize(String language) {
    return switch (language) {
      'id' => 'Ukuran Huruf Arab',
      'en' => 'Arabic Font Size',
      'zh' => '阿拉伯文字体大小',
      'ja' => 'アラビア文字フォントサイズ',
      _ => 'Arabic Font Size',
    };
  }

  static String _getTextSettingsTranslationSize(String language) {
    return switch (language) {
      'id' => 'Ukuran Huruf Terjemahan',
      'en' => 'Translation Font Size',
      'zh' => '翻译字体大小',
      'ja' => '翻訳フォントサイズ',
      _ => 'Translation Font Size',
    };
  }

  static String _getTextSettingsSizeLabel(String language) {
    return switch (language) {
      'id' => 'Ukuran',
      'en' => 'Size',
      'zh' => '大小',
      'ja' => 'サイズ',
      _ => 'Size',
    };
  }

  static String _getTextSettingsTajweedSubtitle(String language) {
    return switch (language) {
      'id' => 'Aturan tajweed berwarna untuk pelafalan yang benar',
      'en' => 'Color-coded tajweed rules for proper recitation',
      'zh' => '彩色编码的泰吉威德规则，用于正确诵读',
      'ja' => '正しい朗読のための色分けされたタジウィード規則',
      _ => 'Color-coded tajweed rules for proper recitation',
    };
  }

  static String _getApply(String language) {
    return switch (language) {
      'id' => 'Terapkan',
      'en' => 'Apply',
      'zh' => '应用',
      'ja' => '適用',
      _ => 'Apply',
    };
  }

  static String _getTransliterationStyleTitle(String language) {
    return switch (language) {
      'id' => 'Gaya transliterasi',
      'en' => 'Transliteration style',
      'zh' => '音译样式',
      'ja' => '音訳スタイル',
      _ => 'Transliteration style',
    };
  }

  static String _getTransliterationStyleOriginal(String language) {
    return switch (language) {
      'id' => 'Tanpa tajwid',
      'en' => 'Without tajweed',
      'zh' => '无泰吉威德',
      'ja' => 'タジウィードなし',
      _ => 'Without tajweed',
    };
  }

  static String _getTransliterationStyleReadable(String language) {
    return switch (language) {
      'id' => 'Mudah dibaca (Disarankan)',
      'en' => 'Readable (Recommended)',
      'zh' => '易读（推荐）',
      'ja' => '読みやすい（推奨）',
      _ => 'Readable (Recommended)',
    };
  }

  static String _getTransliterationStyleRaw(String language) {
    return switch (language) {
      'id' => 'Persis (teks asli)',
      'en' => 'Raw (exact text)',
      'zh' => '原始文本',
      'ja' => 'そのまま',
      _ => 'Raw (exact text)',
    };
  }

  static String _getTransliterationSourceTitle(String language) {
    return switch (language) {
      'id' => 'Sumber transliterasi',
      'en' => 'Transliteration source',
      'zh' => '音译来源',
      'ja' => '音訳ソース',
      _ => 'Transliteration source',
    };
  }

  static String _getTransliterationSourceTajweed(String language) {
    return switch (language) {
      'id' => 'Tajwid (pelafalan, disarankan)',
      'en' => 'Tajweed (pronunciation, recommended)',
      'zh' => '塔吉维德（发音，推荐）',
      'ja' => 'タジウィード（発音、推奨）',
      _ => 'Tajweed (pronunciation, recommended)',
    };
  }

  /// Transliteration without tajweed (scripted text-by-text, no pronunciation adjustment).
  static String _getTransliterationSourceOriginal(String language) {
    return switch (language) {
      'id' => 'Tanpa tajwid',
      'en' => 'Without tajweed',
      'zh' => '无泰吉威德',
      'ja' => 'タジウィードなし',
      _ => 'Without tajweed',
    };
  }

  static String _getTransliterationChoiceTitle(String language) {
    return switch (language) {
      'id' => 'Transliterasi',
      'en' => 'Transliteration',
      'zh' => '音译',
      'ja' => '音訳',
      _ => 'Transliteration',
    };
  }

  static String _getLanguageNameIndonesian(String language) {
    return switch (language) {
      'id' => 'Bahasa Indonesia',
      'en' => 'Indonesian',
      'zh' => '印度尼西亚语',
      'ja' => 'インドネシア語',
      _ => 'Indonesian',
    };
  }

  static String _getLanguageNameEnglish(String language) {
    return switch (language) {
      'id' => 'Bahasa Inggris',
      'en' => 'English',
      'zh' => '英语',
      'ja' => '英語',
      _ => 'English',
    };
  }

  static String _getLanguageNameChinese(String language) {
    return switch (language) {
      'id' => 'Bahasa Mandarin',
      'en' => 'Chinese',
      'zh' => '中文',
      'ja' => '中国語',
      _ => 'Chinese',
    };
  }

  static String _getLanguageNameJapanese(String language) {
    return switch (language) {
      'id' => 'Bahasa Jepang',
      'en' => 'Japanese',
      'zh' => '日语',
      'ja' => '日本語',
      _ => 'Japanese',
    };
  }

  static String _getNotesSubtitle(String language) {
    return switch (language) {
      'id' => 'Catatan pribadi Anda',
      'en' => 'Your personal notes',
      'zh' => '您的个人笔记',
      'ja' => 'あなたの個人的なメモ',
      _ => 'Your personal notes',
    };
  }

  static String _getNotesSearchHint(String language) {
    return switch (language) {
      'id' => 'Cari catatan...',
      'en' => 'Search notes...',
      'zh' => '搜索笔记...',
      'ja' => 'メモを検索...',
      _ => 'Search notes...',
    };
  }

  static String _getNotesEmpty(String language) {
    return switch (language) {
      'id' => 'Belum ada catatan',
      'en' => 'No notes yet',
      'zh' => '还没有笔记',
      'ja' => 'メモがまだありません',
      _ => 'No notes yet',
    };
  }

  static String _getNotesNoResults(String language) {
    return switch (language) {
      'id' => 'Tidak ada hasil',
      'en' => 'No results found',
      'zh' => '未找到结果',
      'ja' => '結果が見つかりません',
      _ => 'No results found',
    };
  }

  static String _getNotes(String language) {
    return switch (language) {
      'id' => 'Catatan',
      'en' => 'Notes',
      'zh' => '笔记',
      'ja' => 'メモ',
      _ => 'Notes',
    };
  }

  static String _getHighlights(String language) {
    return switch (language) {
      'id' => 'Sorotan',
      'en' => 'Highlights',
      'zh' => '高亮',
      'ja' => 'ハイライト',
      _ => 'Highlights',
    };
  }

  static String _getHighlightsSearchHint(String language) {
    return switch (language) {
      'id' => 'Cari sorotan...',
      'en' => 'Search highlights...',
      'zh' => '搜索高亮...',
      'ja' => 'ハイライトを検索...',
      _ => 'Search highlights...',
    };
  }

  static String _getHighlightsEmpty(String language) {
    return switch (language) {
      'id' => 'Belum ada sorotan',
      'en' => 'No highlights yet',
      'zh' => '还没有高亮',
      'ja' => 'ハイライトがまだありません',
      _ => 'No highlights yet',
    };
  }

  static String _getHighlightsNoResults(String language) {
    return switch (language) {
      'id' => 'Tidak ada hasil',
      'en' => 'No results found',
      'zh' => '未找到结果',
      'ja' => '結果が見つかりません',
      _ => 'No results found',
    };
  }

  static String _getLibrarySubtitle(String language) {
    return switch (language) {
      'id' => 'Koleksi pribadi Anda',
      'en' => 'Your personal collection',
      'zh' => '您的个人收藏',
      'ja' => 'あなたの個人的なコレクション',
      _ => 'Your personal collection',
    };
  }

  static String _getDuaSubtitle(String language) {
    return switch (language) {
      'id' => 'Doa, sains, Asmaul Husna, tema hidup',
      'en' => 'Prayers, science, names of Allah, life themes',
      'zh' => '祈祷、科学、真主美名、生活主题',
      'ja' => '祈り、科学、アッラーの美名、生活のテーマ',
      _ => 'Prayers, science, names of Allah, life themes',
    };
  }

  static String _getLibrary(String language) {
    return switch (language) {
      'id' => 'Perpustakaan',
      'en' => 'My Library',
      'zh' => '我的图书馆',
      'ja' => 'マイライブラリ',
      _ => 'My Library',
    };
  }

  static String _getLibraryNav(String language) {
    return switch (language) {
      'id' => 'Koleksi',
      'en' => 'Library',
      'zh' => '收藏',
      'ja' => 'ライブラリ',
      _ => 'Library',
    };
  }

  static String _getSettingsNav(String language) {
    return switch (language) {
      'id' => 'Atur',
      'en' => 'Settings',
      'zh' => '设置',
      'ja' => '設定',
      _ => 'Settings',
    };
  }

  static String _getDua(String language) {
    return switch (language) {
      'id' => 'Jelajahi',
      'en' => 'Explore',
      'zh' => '探索',
      'ja' => '探求',
      _ => 'Explore',
    };
  }

  static String _getLibrarySearchHint(String language) {
    return switch (language) {
      'id' => 'Cari di semua koleksi...',
      'en' => 'Search all collections...',
      'zh' => '搜索所有收藏...',
      'ja' => 'すべてのコレクションを検索...',
      _ => 'Search all collections...',
    };
  }

  static String _getLibraryNoResults(String language) {
    return switch (language) {
      'id' => 'Tidak ada hasil ditemukan',
      'en' => 'No results found',
      'zh' => '未找到结果',
      'ja' => '結果が見つかりません',
      _ => 'No results found',
    };
  }

  // Highlight Guide Localizations
  static String _getHighlightGuideTitle(String language) {
    return switch (language) {
      'id' => 'Panduan Warna Highlight',
      'en' => 'Highlight Color Guide',
      'zh' => '高亮颜色指南',
      'ja' => 'ハイライトカラーガイド',
      _ => 'Highlight Color Guide',
    };
  }

  static String _getHighlightGuideIntro(String language) {
    return switch (language) {
      'id' => 'Warna berikut dapat digunakan untuk mengkategorikan ayat yang Anda highlight:',
      'en' => 'The following colors can be used to categorize verses you highlight:',
      'zh' => '以下颜色可用于对您高亮的经文进行分类：',
      'ja' => '次の色を使用して、ハイライトした節を分類できます：',
      _ => 'The following colors can be used to categorize verses you highlight:',
    };
  }

  static String _getHighlightGuideClosing(String language) {
    return switch (language) {
      'id' => 'Gunakan warna yang berbeda untuk mengorganisir dan mengkategorikan ayat-ayat penting Anda.',
      'en' => 'Use different colors to organize and categorize your important verses.',
      'zh' => '使用不同的颜色来组织和分类您的重要经文。',
      'ja' => '異なる色を使用して、重要な節を整理して分類します。',
      _ => 'Use different colors to organize and categorize your important verses.',
    };
  }

  static String _getHighlightGuideGotIt(String language) {
    return switch (language) {
      'id' => 'Mengerti',
      'en' => 'Got it',
      'zh' => '知道了',
      'ja' => '了解しました',
      _ => 'Got it',
    };
  }

  // Highlight Color Names and Descriptions
  static String _getHighlightColorYellow(String language) {
    return switch (language) {
      'id' => 'Kuning',
      'en' => 'Yellow',
      'zh' => '黄色',
      'ja' => '黄色',
      _ => 'Yellow',
    };
  }

  static String _getHighlightColorYellowDesc(String language) {
    return switch (language) {
      'id' => 'Favorit atau ayat penting',
      'en' => 'Favorite or important verses',
      'zh' => '收藏或重要经文',
      'ja' => 'お気に入りまたは重要な節',
      _ => 'Favorite or important verses',
    };
  }

  static String _getHighlightColorOrange(String language) {
    return switch (language) {
      'id' => 'Jingga',
      'en' => 'Orange',
      'zh' => '橙色',
      'ja' => 'オレンジ',
      _ => 'Orange',
    };
  }

  static String _getHighlightColorOrangeDesc(String language) {
    return switch (language) {
      'id' => 'Ayat yang menginspirasi atau memotivasi',
      'en' => 'Inspiring or motivating verses',
      'zh' => '鼓舞或激励的经文',
      'ja' => 'インスピレーションを与えるまたは動機付けする節',
      _ => 'Inspiring or motivating verses',
    };
  }

  static String _getHighlightColorPink(String language) {
    return switch (language) {
      'id' => 'Merah Muda',
      'en' => 'Pink',
      'zh' => '粉色',
      'ja' => 'ピンク',
      _ => 'Pink',
    };
  }

  static String _getHighlightColorPinkDesc(String language) {
    return switch (language) {
      'id' => 'Ayat tentang cinta dan kasih sayang',
      'en' => 'Verses about love and compassion',
      'zh' => '关于爱与慈悲的经文',
      'ja' => '愛と慈悲についての節',
      _ => 'Verses about love and compassion',
    };
  }

  static String _getHighlightColorRed(String language) {
    return switch (language) {
      'id' => 'Merah',
      'en' => 'Red',
      'zh' => '红色',
      'ja' => '赤',
      _ => 'Red',
    };
  }

  static String _getHighlightColorRedDesc(String language) {
    return switch (language) {
      'id' => 'Ayat penting atau peringatan',
      'en' => 'Important verses or warnings',
      'zh' => '重要经文或警告',
      'ja' => '重要な節または警告',
      _ => 'Important verses or warnings',
    };
  }

  static String _getHighlightColorPurple(String language) {
    return switch (language) {
      'id' => 'Ungu',
      'en' => 'Purple',
      'zh' => '紫色',
      'ja' => '紫',
      _ => 'Purple',
    };
  }

  static String _getHighlightColorPurpleDesc(String language) {
    return switch (language) {
      'id' => 'Ayat untuk dihafal atau dipelajari',
      'en' => 'Verses to memorize or study',
      'zh' => '需要记忆或学习的经文',
      'ja' => '暗記または学習する節',
      _ => 'Verses to memorize or study',
    };
  }

  static String _getHighlightColorBlue(String language) {
    return switch (language) {
      'id' => 'Biru',
      'en' => 'Blue',
      'zh' => '蓝色',
      'ja' => '青',
      _ => 'Blue',
    };
  }

  static String _getHighlightColorBlueDesc(String language) {
    return switch (language) {
      'id' => 'Ayat tentang pengetahuan atau hikmah',
      'en' => 'Verses about knowledge or wisdom',
      'zh' => '关于知识或智慧的经文',
      'ja' => '知識や知恵についての節',
      _ => 'Verses about knowledge or wisdom',
    };
  }

  static String _getHighlightColorCyan(String language) {
    return switch (language) {
      'id' => 'Cyan',
      'en' => 'Cyan',
      'zh' => '青色',
      'ja' => 'シアン',
      _ => 'Cyan',
    };
  }

  static String _getHighlightColorCyanDesc(String language) {
    return switch (language) {
      'id' => 'Ayat tentang ketenangan atau kedamaian',
      'en' => 'Verses about tranquility or peace',
      'zh' => '关于宁静或和平的经文',
      'ja' => '静けさや平和についての節',
      _ => 'Verses about tranquility or peace',
    };
  }

  static String _getHighlightColorGreen(String language) {
    return switch (language) {
      'id' => 'Hijau',
      'en' => 'Green',
      'zh' => '绿色',
      'ja' => '緑',
      _ => 'Green',
    };
  }

  static String _getHighlightColorGreenDesc(String language) {
    return switch (language) {
      'id' => 'Ayat tentang harapan atau keberhasilan',
      'en' => 'Verses about hope or success',
      'zh' => '关于希望或成功的经文',
      'ja' => '希望や成功についての節',
      _ => 'Verses about hope or success',
    };
  }

  static String _getHighlightColorTeal(String language) {
    return switch (language) {
      'id' => 'Teal',
      'en' => 'Teal',
      'zh' => '青绿色',
      'ja' => 'ティール',
      _ => 'Teal',
    };
  }

  static String _getHighlightColorTealDesc(String language) {
    return switch (language) {
      'id' => 'Ayat tentang alam atau ciptaan',
      'en' => 'Verses about nature or creation',
      'zh' => '关于自然或创造的经文',
      'ja' => '自然や創造についての節',
      _ => 'Verses about nature or creation',
    };
  }

  static String _getHighlightColorOther(String language) {
    return switch (language) {
      'id' => 'Lainnya',
      'en' => 'Other',
      'zh' => '其他',
      'ja' => 'その他',
      _ => 'Other',
    };
  }

  static String _getHighlightColorOtherDesc(String language) {
    return switch (language) {
      'id' => 'Kategori khusus Anda',
      'en' => 'Your custom category',
      'zh' => '您的自定义类别',
      'ja' => 'カスタムカテゴリ',
      _ => 'Your custom category',
    };
  }

  static String _getSelected(String language) {
    return switch (language) {
      'id' => 'terpilih',
      'en' => 'selected',
      'zh' => '已选择',
      'ja' => '選択済み',
      _ => 'selected',
    };
  }

  /// Get localized text for share header "Allah Subhanahu Wa Ta'ala berfirman:"
  static String getShareHeader(String language) {
    return switch (language) {
      'id' => 'Allah Subhanahu Wa Ta\'ala berfirman:',
      'en' => 'Allah Subhanahu Wa Ta\'ala says:',
      'zh' => '真主说：',
      'ja' => 'アッラーは仰せられました：',
      _ => 'Allah Subhanahu Wa Ta\'ala says:',
    };
  }

  /// Get localized text for "Ayah" in reference format
  static String getAyahLabel(String language) {
    return switch (language) {
      'id' => 'Ayat',
      'en' => 'Ayah',
      'zh' => '节',
      'ja' => '節',
      _ => 'Ayah',
    };
  }

  /// Get localized label for verse translation heading (sheet / ayah card)
  static String getMeaningLabel(String language) {
    return switch (language) {
      'id' => 'Terjemahan',
      'en' => 'Translation',
      'zh' => '翻译',
      'ja' => '翻訳',
      _ => 'Translation',
    };
  }

  // ===========================================================================
  // Recitation / Audio downloads
  // ===========================================================================

  /// Get localized text for simple (non-parameterized) recitation strings.
  static String getRecitationText(String key, String language) {
    return switch (key) {
      'recitation_section' => _recRecitationSection(language),
      'reciter' => _recReciter(language),
      'save_recitation_audio' => _recSaveRecitationAudio(language),
      'recitation_downloads' => _recRecitationDownloads(language),
      'saved_on_device' => _recSavedOnDevice(language),
      'not_saved' => _recNotSaved(language),
      'failed_retry' => _recFailedRetry(language),
      'cancel' => _getCancel(language),
      'delete' => _getDelete(language),
      'save' => _getSave(language),
      'save_action' => _getSave(language),
      'save_surah_action' => _recSaveSurahAction(language),
      'save_all_114' => _recSaveAll114(language),
      'cancel_save_all' => _recCancelSaveAll(language),
      'recommended_smooth' => _recRecommendedSmooth(language),
      'storage_on_phone' => _recStorageOnPhone(language),
      'storage_phone_desc' => _recStoragePhoneDesc(language),
      'no_files_saved' => _recNoFilesSaved(language),
      'delete_all_recitation_q' => _recDeleteAllQuestion(language),
      'selected_for_playback' => _recSelectedForPlayback(language),
      'all_surahs_saved' => _recAllSurahsSaved(language),
      _ => key,
    };
  }

  static String _recRecitationSection(String language) {
    return switch (language) {
      'id' => 'Tilawah',
      'en' => 'Recitation',
      'zh' => '诵读',
      'ja' => '朗読',
      _ => 'Recitation',
    };
  }

  static String _recReciter(String language) {
    return switch (language) {
      'id' => 'Qari',
      'en' => 'Reciter',
      'zh' => '诵读者',
      'ja' => '朗読者',
      _ => 'Reciter',
    };
  }

  static String _recSaveRecitationAudio(String language) {
    return switch (language) {
      'id' => 'Simpan audio tilawah',
      'en' => 'Save recitation audio',
      'zh' => '保存诵读音频',
      'ja' => '朗読音声を保存',
      _ => 'Save recitation audio',
    };
  }

  static String _recRecitationDownloads(String language) {
    return switch (language) {
      'id' => 'Unduhan Tilawah',
      'en' => 'Recitation Downloads',
      'zh' => '诵读下载',
      'ja' => '朗読のダウンロード',
      _ => 'Recitation Downloads',
    };
  }

  static String _recSavedOnDevice(String language) {
    return switch (language) {
      'id' => 'Tersimpan di perangkat',
      'en' => 'Saved on device',
      'zh' => '已保存到设备',
      'ja' => '端末に保存済み',
      _ => 'Saved on device',
    };
  }

  static String _recNotSaved(String language) {
    return switch (language) {
      'id' => 'Belum tersimpan',
      'en' => 'Not saved',
      'zh' => '未保存',
      'ja' => '未保存',
      _ => 'Not saved',
    };
  }

  static String _recFailedRetry(String language) {
    return switch (language) {
      'id' => 'Gagal - ketuk untuk coba lagi',
      'en' => 'Failed - tap to retry',
      'zh' => '失败 - 点按重试',
      'ja' => '失敗 - タップして再試行',
      _ => 'Failed - tap to retry',
    };
  }

  static String _recSaveSurahAction(String language) {
    return switch (language) {
      'id' => 'Simpan surah',
      'en' => 'Save surah',
      'zh' => '保存整章',
      'ja' => '章を保存',
      _ => 'Save surah',
    };
  }

  static String _recSaveAll114(String language) {
    return switch (language) {
      'id' => 'Simpan semua 114 surah',
      'en' => 'Save all 114 surahs',
      'zh' => '保存全部114章',
      'ja' => '全114章を保存',
      _ => 'Save all 114 surahs',
    };
  }

  static String _recCancelSaveAll(String language) {
    return switch (language) {
      'id' => 'Batalkan simpan semua',
      'en' => 'Cancel save all',
      'zh' => '取消全部保存',
      'ja' => 'すべての保存をキャンセル',
      _ => 'Cancel save all',
    };
  }

  static String _recRecommendedSmooth(String language) {
    return switch (language) {
      'id' => 'Disarankan agar pemutaran lancar tanpa indikator memuat.',
      'en' => 'Recommended for smooth playback with no loading spinners.',
      'zh' => '建议保存以获得流畅播放，无需加载等待。',
      'ja' => '読み込み表示なしのスムーズな再生に推奨。',
      _ => 'Recommended for smooth playback with no loading spinners.',
    };
  }

  static String _recStorageOnPhone(String language) {
    return switch (language) {
      'id' => 'Penyimpanan di ponsel Anda',
      'en' => 'Storage on your phone',
      'zh' => '手机存储',
      'ja' => '端末のストレージ',
      _ => 'Storage on your phone',
    };
  }

  static String _recStoragePhoneDesc(String language) {
    return switch (language) {
      'id' => 'Mengunduh setiap qari memakai lebih banyak ruang. Hapus suara yang tidak Anda perlukan lagi.',
      'en' => 'Downloading every reciter uses more space. Remove voices you no longer need.',
      'zh' => '下载每位诵读者会占用更多空间。删除您不再需要的声音。',
      'ja' => 'すべての朗読者をダウンロードすると容量を多く使います。不要な音声は削除してください。',
      _ => 'Downloading every reciter uses more space. Remove voices you no longer need.',
    };
  }

  static String _recNoFilesSaved(String language) {
    return switch (language) {
      'id' => 'Belum ada file tilawah yang tersimpan.',
      'en' => 'No recitation files saved yet.',
      'zh' => '尚未保存诵读文件。',
      'ja' => '保存された朗読ファイルはまだありません。',
      _ => 'No recitation files saved yet.',
    };
  }

  static String _recDeleteAllQuestion(String language) {
    return switch (language) {
      'id' => 'Hapus semua audio tilawah?',
      'en' => 'Delete all recitation audio?',
      'zh' => '删除所有诵读音频？',
      'ja' => 'すべての朗読音声を削除しますか？',
      _ => 'Delete all recitation audio?',
    };
  }

  static String _recSelectedForPlayback(String language) {
    return switch (language) {
      'id' => 'dipilih untuk pemutaran',
      'en' => 'selected for playback',
      'zh' => '已选用于播放',
      'ja' => '再生用に選択済み',
      _ => 'selected for playback',
    };
  }

  static String _recAllSurahsSaved(String language) {
    return switch (language) {
      'id' => 'Semua 114 surah tersimpan di perangkat Anda. Tilawah berfungsi sepenuhnya offline.',
      'en' => 'All 114 surahs are saved on your device. Recitation works fully offline.',
      'zh' => '全部114章已保存到您的设备。诵读可完全离线使用。',
      'ja' => '全114章を端末に保存しました。朗読は完全にオフラインで動作します。',
      _ => 'All 114 surahs are saved on your device. Recitation works fully offline.',
    };
  }

  // --- Parameterized recitation strings -------------------------------------

  static String recAllSavedFor(String name, String language) {
    return switch (language) {
      'id' => 'Semua 114 surah tersimpan untuk $name',
      'en' => 'All 114 surahs saved for $name',
      'zh' => '已为 $name 保存全部114章',
      'ja' => '$name の全114章を保存済み',
      _ => 'All 114 surahs saved for $name',
    };
  }

  static String recSavedForReciterShort(
    int saved,
    int total,
    String name,
    String language,
  ) {
    return switch (language) {
      'id' => '$saved/$total tersimpan untuk $name — setiap qari terpisah',
      'en' => '$saved/$total saved for $name — each reciter is separate',
      'zh' => '已为 $name 保存 $saved/$total — 每位诵读者独立',
      'ja' => '$name に $saved/$total を保存 — 朗読者ごとに別々',
      _ => '$saved/$total saved for $name — each reciter is separate',
    };
  }

  static String recReciterSeparateHeader(String name, String language) {
    return switch (language) {
      'id' => 'Setiap qari memiliki audio terpisah di ponsel Anda. Menyimpan di sini hanya berlaku untuk $name. Qari lain tidak ditimpa.',
      'en' => 'Each reciter has separate audio on your phone. Saving here only applies to $name. Other reciters are not overwritten.',
      'zh' => '每位诵读者在您的手机上都有独立的音频。在此保存仅适用于 $name。其他诵读者不会被覆盖。',
      'ja' => '各朗読者は端末に別々の音声を持ちます。ここでの保存は $name のみに適用されます。他の朗読者は上書きされません。',
      _ => 'Each reciter has separate audio on your phone. Saving here only applies to $name. Other reciters are not overwritten.',
    };
  }

  static String recSavedForThisReciter(int saved, int total, String language) {
    return switch (language) {
      'id' => 'Tersimpan untuk qari ini: $saved/$total surah',
      'en' => 'Saved for this reciter: $saved/$total surahs',
      'zh' => '已为此诵读者保存：$saved/$total 章',
      'ja' => 'この朗読者の保存済み：$saved/$total 章',
      _ => 'Saved for this reciter: $saved/$total surahs',
    };
  }

  static String recStorageForReciter(String name, String size, String language) {
    return switch (language) {
      'id' => 'Penyimpanan untuk $name: $size',
      'en' => 'Storage for $name: $size',
      'zh' => '$name 的存储：$size',
      'ja' => '$name のストレージ：$size',
      _ => 'Storage for $name: $size',
    };
  }

  static String recTotalAllReciters(String size, String language) {
    return switch (language) {
      'id' => 'Total semua qari: $size',
      'en' => 'Total for all reciters: $size',
      'zh' => '所有诵读者总计：$size',
      'ja' => '全朗読者の合計：$size',
      _ => 'Total for all reciters: $size',
    };
  }

  static String recOtherRecitersUseSpace(int count, String language) {
    return switch (language) {
      'id' => '$count qari lain juga memakai ruang di ponsel Anda. Lihat di bawah untuk mengosongkan penyimpanan.',
      'en' => '$count other reciter(s) also use space on your phone. See below to free storage.',
      'zh' => '另有 $count 位诵读者也占用您手机的空间。请见下方以释放存储。',
      'ja' => '他に $count 人の朗読者も端末の容量を使用しています。空き容量を増やすには下記をご覧ください。',
      _ => '$count other reciter(s) also use space on your phone. See below to free storage.',
    };
  }

  static String recSavingSurah(String surahId, int done, int total, String language) {
    return switch (language) {
      'id' => 'Menyimpan surah $surahId ($done/$total)',
      'en' => 'Saving surah $surahId ($done/$total)',
      'zh' => '正在保存第 $surahId 章（$done/$total）',
      'ja' => '章 $surahId を保存中（$done/$total）',
      _ => 'Saving surah $surahId ($done/$total)',
    };
  }

  static String recDeleteAllAudioForReciter(String name, String language) {
    return switch (language) {
      'id' => 'Hapus semua audio untuk $name',
      'en' => 'Delete all audio for $name',
      'zh' => '删除 $name 的所有音频',
      'ja' => '$name のすべての音声を削除',
      _ => 'Delete all audio for $name',
    };
  }

  static String recDeleteAllRecitationAudioBtn(String size, String language) {
    return switch (language) {
      'id' => 'Hapus semua audio tilawah ($size)',
      'en' => 'Delete all recitation audio ($size)',
      'zh' => '删除所有诵读音频（$size）',
      'ja' => 'すべての朗読音声を削除（$size）',
      _ => 'Delete all recitation audio ($size)',
    };
  }

  static String recSurahsMarkedSaved(int count, String language) {
    return switch (language) {
      'id' => '$count surah ditandai tersimpan',
      'en' => '$count surahs marked saved',
      'zh' => '$count 章已标记保存',
      'ja' => '$count 章を保存済みとマーク',
      _ => '$count surahs marked saved',
    };
  }

  static String recDeleteReciterTitle(String name, String language) {
    return switch (language) {
      'id' => 'Hapus audio $name?',
      'en' => 'Delete $name audio?',
      'zh' => '删除 $name 的音频？',
      'ja' => '$name の音声を削除しますか？',
      _ => 'Delete $name audio?',
    };
  }

  static String recDeleteReciterMessage(String name, String language) {
    return switch (language) {
      'id' => 'Ini menghapus semua file tilawah $name yang tersimpan dari ponsel Anda. Anda dapat menyimpannya lagi nanti.',
      'en' => 'This removes all saved recitation files for $name from your phone. You can save them again later.',
      'zh' => '这将从您的手机中删除 $name 所有已保存的诵读文件。您可以稍后重新保存。',
      'ja' => 'これにより、$name の保存済み朗読ファイルがすべて端末から削除されます。後で再度保存できます。',
      _ => 'This removes all saved recitation files for $name from your phone. You can save them again later.',
    };
  }

  static String recDeleteAllMessage(String size, String language) {
    return switch (language) {
      'id' => 'Ini mengosongkan $size dengan menghapus audio tersimpan untuk semua qari. Pemutaran akan memerlukan internet atau unduhan baru.',
      'en' => 'This frees $size by removing saved audio for every reciter. Playback will need the internet or a new download.',
      'zh' => '这将通过删除所有诵读者的已保存音频释放 $size。播放将需要联网或重新下载。',
      'ja' => 'これにより、すべての朗読者の保存済み音声を削除して $size を解放します。再生にはインターネットまたは再ダウンロードが必要になります。',
      _ => 'This frees $size by removing saved audio for every reciter. Playback will need the internet or a new download.',
    };
  }

  static String recDownloadingProgress(int done, int total, String language) {
    return switch (language) {
      'id' => 'Mengunduh $done/$total',
      'en' => 'Downloading $done/$total',
      'zh' => '正在下载 $done/$total',
      'ja' => 'ダウンロード中 $done/$total',
      _ => 'Downloading $done/$total',
    };
  }

  static String recError(Object error, String language) {
    return switch (language) {
      'id' => 'Kesalahan: $error',
      'en' => 'Error: $error',
      'zh' => '错误：$error',
      'ja' => 'エラー：$error',
      _ => 'Error: $error',
    };
  }

  static String recSurahSaved(
    String label,
    int count,
    int total,
    String language,
  ) {
    return switch (language) {
      'id' => '$label tersimpan di perangkat Anda ($count/$total surah). Pemutaran kini seketika untuk surah ini.',
      'en' => '$label saved on your device ($count/$total surahs). Playback is now instant for this surah.',
      'zh' => '$label 已保存到您的设备（$count/$total 章）。该章现在可即时播放。',
      'ja' => '$label を端末に保存しました（$count/$total 章）。この章はすぐに再生できます。',
      _ => '$label saved on your device ($count/$total surahs). Playback is now instant for this surah.',
    };
  }

  static String recPreparingLargeWhole(String name, String language) {
    return switch (language) {
      'id' => '$name belum tersimpan di perangkat Anda. Putar surah mungkin menampilkan indikator memuat saat ayat diambil dari internet. Simpan seluruh surah untuk pemutaran offline seketika.',
      'en' => '$name is not saved on your device yet. Play surah may show a loading spinner while verses stream from the internet. Save the full surah for instant offline playback.',
      'zh' => '$name 尚未保存到您的设备。播放整章时，经文从网络加载可能出现加载指示。保存整章可立即离线播放。',
      'ja' => '$name はまだ端末に保存されていません。章を再生すると、節がインターネットから読み込まれる間ローディングが表示される場合があります。章全体を保存すると、すぐにオフライン再生できます。',
      _ => '$name is not saved on your device yet. Play surah may show a loading spinner while verses stream from the internet. Save the full surah for instant offline playback.',
    };
  }

  static String recPreparingLarge(String name, String language) {
    return switch (language) {
      'id' => '$name belum tersimpan sepenuhnya. Ayat ini mungkin butuh waktu sejenak untuk mulai. Simpan surah untuk pemutaran offline yang lancar.',
      'en' => '$name is not fully saved. This verse may take a moment to start. Save the surah for smooth offline playback.',
      'zh' => '$name 尚未完全保存。这节经文可能需要片刻才能开始。保存该章以获得流畅的离线播放。',
      'ja' => '$name は完全には保存されていません。この節は開始までに少し時間がかかる場合があります。スムーズなオフライン再生のために章を保存してください。',
      _ => '$name is not fully saved. This verse may take a moment to start. Save the surah for smooth offline playback.',
    };
  }

  static String recPreparingSmall(String name, String language) {
    return switch (language) {
      'id' => '$name belum tersimpan di perangkat Anda. Simpan untuk pemutaran seketika tanpa menunggu.',
      'en' => '$name is not saved on your device yet. Save it for instant playback without waiting.',
      'zh' => '$name 尚未保存到您的设备。保存后可立即播放，无需等待。',
      'ja' => '$name はまだ端末に保存されていません。待たずにすぐ再生できるよう保存してください。',
      _ => '$name is not saved on your device yet. Save it for instant playback without waiting.',
    };
  }

  static String recStreamingReminder(String label, String language) {
    return switch (language) {
      'id' => 'Memutar $label menggunakan internet. Simpan di perangkat Anda untuk pemutaran offline.',
      'en' => 'Playing $label using the internet. Save it on your device for offline playback.',
      'zh' => '正在使用网络播放 $label。将其保存到设备以便离线播放。',
      'ja' => 'インターネットを使用して $label を再生中。オフライン再生のために端末に保存してください。',
      _ => 'Playing $label using the internet. Save it on your device for offline playback.',
    };
  }

  static String recNotSavedOnDevice(String label, String language) {
    return switch (language) {
      'id' => '$label belum tersimpan di perangkat Anda. Ketuk Simpan untuk mengunduh surah ini untuk pemutaran offline.',
      'en' => '$label is not saved on your device. Tap Save to download this surah for offline playback.',
      'zh' => '$label 尚未保存到您的设备。点按"保存"下载该章以便离线播放。',
      'ja' => '$label は端末に保存されていません。「保存」をタップしてこの章をダウンロードするとオフライン再生できます。',
      _ => '$label is not saved on your device. Tap Save to download this surah for offline playback.',
    };
  }
}

