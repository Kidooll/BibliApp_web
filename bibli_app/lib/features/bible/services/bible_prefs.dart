import 'package:shared_preferences/shared_preferences.dart';

class BiblePrefs {
  static const _translationKey = 'bible_translation_v1';
  static const _defaultTranslation = 'NVIPT';

  static Future<String> getTranslation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_translationKey) ?? _defaultTranslation;
  }

  static Future<void> setTranslation(String translation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_translationKey, translation);
  }
}
