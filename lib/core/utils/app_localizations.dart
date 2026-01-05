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

  static String _getLibrary(String language) {
    return switch (language) {
      'id' => 'Perpustakaan',
      'en' => 'My Library',
      'zh' => '我的图书馆',
      'ja' => 'マイライブラリ',
      _ => 'My Library',
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
}

