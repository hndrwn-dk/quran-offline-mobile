import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/features/home/widgets/home_backdrop.dart';
import 'package:quran_offline/features/settings/widgets/settings_menu_app_bar.dart';
import 'package:quran_offline/features/settings/widgets/settings_sections.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topTint = HomeBackdrop.topTint(Theme.of(context).colorScheme);

    return Scaffold(
      backgroundColor: topTint,
      appBar: SettingsMenuAppBar(showBackButton: showBackButton),
      body: HomeBackdrop(
        child: ListView(
          children: const [
            SettingsQuranSection(),
            Divider(),
            SettingsRecitationSection(),
            Divider(),
            SettingsRemindersSection(),
            Divider(),
            SettingsAppSection(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
