import 'app_settings.dart';

// The cubit only knows about this, so tests can pass in a fake.
abstract class SettingsRepository {
  // Anything not saved yet comes back as the default value.
  Future<AppSettings> load();

  Future<void> saveLanguage(String languageCode);

  Future<void> saveThemeMode(AppThemeMode themeMode);

  Future<void> saveDefaultDepartureCity(String city);
}
