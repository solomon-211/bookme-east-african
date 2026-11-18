import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';
import 'settings_state.dart';

// Lives at the top of the app so MaterialApp can rebuild when the theme
// changes, and Search can read the default departure city.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository, {AppSettings? initial})
    : super(
        initial == null
            ? const SettingsState()
            : SettingsState(settings: initial, loaded: true),
      );

  final SettingsRepository _repository;

  Future<void> load() async {
    final saved = await _repository.loadSettings();
    emit(SettingsState(settings: saved, loaded: true));
  }

  // The screen updates straight away; the write to the phone happens after.
  Future<void> changeLanguage(String languageCode) async {
    if (!AppSettings.supportedLanguages.contains(languageCode)) return;
    if (languageCode == state.settings.languageCode) return;

    _update(state.settings.copyWith(languageCode: languageCode));
    await _repository.saveLanguage(languageCode);
  }

  Future<void> changeThemeMode(AppThemeMode themeMode) async {
    if (themeMode == state.settings.themeMode) return;

    _update(state.settings.copyWith(themeMode: themeMode));
    await _repository.saveThemeMode(themeMode);
  }

  Future<void> changeDefaultDepartureCity(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty || trimmed == state.settings.defaultDepartureCity) {
      return;
    }

    _update(state.settings.copyWith(defaultDepartureCity: trimmed));
    await _repository.saveDefaultDepartureCity(trimmed);
  }

  void _update(AppSettings settings) {
    emit(state.copyWith(settings: settings, loaded: true));
  }
}
