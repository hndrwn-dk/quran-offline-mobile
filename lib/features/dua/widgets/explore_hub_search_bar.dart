import 'package:flutter/material.dart';
import 'package:quran_offline/core/utils/app_localizations.dart';
import 'package:quran_offline/core/widgets/app_search_field.dart';

export 'package:quran_offline/core/widgets/app_search_field.dart'
    show kAppContentHorizontalInset;

/// Jelajahi hub search — delegates to shared [AppSearchField].
class ExploreHubSearchBar extends StatelessWidget {
  const ExploreHubSearchBar({
    super.key,
    required this.lang,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final String lang;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      controller: controller,
      focusNode: focusNode,
      hintText: AppLocalizations.getExploreSearchHint(lang),
      onChanged: onChanged,
      onClear: onClear,
    );
  }
}
