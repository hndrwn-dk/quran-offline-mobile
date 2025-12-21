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
      _ => key,
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
      'search_subtitle' => _getSearchSubtitle(language),
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

  static String _getSearchSubtitle(String language) {
    return switch (language) {
      'id' => 'Cari di seluruh Al-Qur\'an',
      'en' => 'Search across the Qur\'an',
      'zh' => '搜索古兰经',
      'ja' => 'コーラン全体を検索',
      _ => 'Search across the Qur\'an',
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
      _ => key,
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
      'show_tajweed_title' => _getShowTajweedTitle(language),
      'show_tajweed_subtitle' => _getShowTajweedSubtitle(language),
      'app_settings_header' => _getAppSettingsHeader(language),
      'app_language_title' => _getAppLanguageTitle(language),
      'app_language_subtitle' => _getAppLanguageSubtitle(language),
      'theme_title' => _getThemeTitle(language),
      'theme_subtitle' => _getThemeSubtitle(language),
      'about_header' => _getAboutHeader(language),
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

  static String _getAboutHeader(String language) {
    return switch (language) {
      'id' => 'Tentang',
      'en' => 'About',
      'zh' => '关于',
      'ja' => 'について',
      _ => 'About',
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
}

