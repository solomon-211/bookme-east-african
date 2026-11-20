import 'package:shared_preferences/shared_preferences.dart';

// Thin wrapper around SharedPreferences. Keep all the key names here.
class SettingsLocalSource {
  // "settings." prefix so we don't collide with keys from other features.
  static const languageKey = 'settings.languageCode';
  static const themeModeKey = 'settings.themeMode';
  static const departureCityKey = 'settings.defaultDepartureCity';

  final SharedPreferences _prefs;

  SettingsLocalSource(this._prefs);

  // These return null if the user never changed the setting.
  String? getLanguage() => _prefs.getString(languageKey);
  String? getThemeMode() => _prefs.getString(themeModeKey);
  String? getDefaultDepartureCity() => _prefs.getString(departureCityKey);

  Future<void> setLanguage(String value) =>
      _prefs.setString(languageKey, value);

  Future<void> setThemeMode(String value) =>
      _prefs.setString(themeModeKey, value);

  Future<void> setDefaultDepartureCity(String value) =>
      _prefs.setString(departureCityKey, value);
}
