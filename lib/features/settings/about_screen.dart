import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/settings/widgets/settings_menu_app_bar.dart';
import 'package:quran_offline/features/settings/widgets/settings_sections.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topTint = HomeBackdrop.topTint(Theme.of(context).colorScheme);

    return Scaffold(
      backgroundColor: topTint,
      appBar: const SettingsMenuAppBar(),
      body: HomeBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          children: const [
            SettingsAboutBrandHeader(),
            SizedBox(height: 14),
            SettingsAboutAppSection(),
            SizedBox(height: 14),
            SettingsAboutSupportSection(),
            SizedBox(height: 14),
            SettingsAboutLegalSection(),
            SizedBox(height: 14),
            SettingsAboutFeedbackSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
