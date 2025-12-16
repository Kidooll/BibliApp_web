import 'package:shared_preferences/shared_preferences.dart';

class SleepPrefs {
  static const _welcomeSeenKey = 'sleep_welcome_seen_v1';
  static const _favoritesKey = 'sleep_favorites_v1';

  static Future<bool> isWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeSeenKey) ?? false;
  }

  static Future<void> setWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeSeenKey, true);
  }

  static Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesKey) ?? const <String>[];
    return list.toSet();
  }

  static Future<bool> toggleFavorite(String trackId) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_favoritesKey) ?? const <String>[])
        .toSet();
    final isFav = !set.contains(trackId);
    if (isFav) {
      set.add(trackId);
    } else {
      set.remove(trackId);
    }
    await prefs.setStringList(_favoritesKey, set.toList());
    return isFav;
  }
}
