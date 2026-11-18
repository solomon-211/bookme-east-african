import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';
import 'settings_local_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalSource _source;

  SettingsRepositoryImpl(this._source);

  @override
  Future<AppSettings> loadSettings() async {
    const defaults = AppSettings.defaults;

    return AppSettings(
      languageCode: _readLanguage() ?? defaults.languageCode,
      themeMode: _readThemeMode() ?? defaults.themeMode,
      defaultDepartureCity:
          _source.getDefaultDepartureCity() ?? defaults.defaultDepartureCity,
    );
  }

  @override
  Future<void> saveLanguage(String languageCode) =>
      _source.setLanguage(languageCode);

  // Stored by name ("dark") rather than index, so reordering the enum
  // later won't flip someone's theme.
  @override
  Future<void> saveThemeMode(AppThemeMode themeMode) =>
      _source.setThemeMode(themeMode.name);

  @override
  Future<void> saveDefaultDepartureCity(String city) =>
      _source.setDefaultDepartureCity(city);

  // Ignore a language we no longer support instead of crashing on it.
  String? _readLanguage() {
    final code = _source.getLanguage();
    return AppSettings.supportedLanguages.contains(code) ? code : null;
  }

  // Turn a stored name like "dark" back into AppThemeMode.dark.
  AppThemeMode? _readThemeMode() {
    final name = _source.getThemeMode();
    for (final mode in AppThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return null;
  }
}
