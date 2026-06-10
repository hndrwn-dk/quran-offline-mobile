import 'package:shared_preferences/shared_preferences.dart';



/// Seeds prefs so integration tests skip onboarding (DB import runs normally on splash).

Future<void> seedIntegrationTestPreferences({

  String language = 'id',

  String appLanguage = 'id',

}) async {

  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool('language_selection_done', true);

  await prefs.setString('language', language);

  await prefs.setString('appLanguage', appLanguage);

  // Do not set quran_data_version here — that skips import while the DB is still empty.

}

