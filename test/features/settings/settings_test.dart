import 'package:bloc_test/bloc_test.dart';
import 'package:bookme_summative_project/features/settings/data/settings_local_source.dart';
import 'package:bookme_summative_project/features/settings/data/settings_repository_impl.dart';
import 'package:bookme_summative_project/features/settings/domain/app_settings.dart';
import 'package:bookme_summative_project/features/settings/presentation/settings_cubit.dart';
import 'package:bookme_summative_project/features/settings/presentation/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Builds a repository on top of whatever is in the fake SharedPreferences,
// the same way the app does at launch.
Future<SettingsRepositoryImpl> openRepository() async {
  final prefs = await SharedPreferences.getInstance();
  return SettingsRepositoryImpl(SettingsLocalSource(prefs));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Preferences save and restore', () {
    test('first launch gives the defaults', () async {
      final repo = await openRepository();

      expect(await repo.loadSettings(), AppSettings.defaults);
    });

    test('all three preferences survive an app restart', () async {
      final firstRun = await openRepository();
      await firstRun.saveLanguage('rw');
      await firstRun.saveThemeMode(AppThemeMode.dark);
      await firstRun.saveDefaultDepartureCity('Kampala');

      // A new repository reads the same stored values, like a relaunch.
      final secondRun = await openRepository();

      expect(
        await secondRun.loadSettings(),
        const AppSettings(
          languageCode: 'rw',
          themeMode: AppThemeMode.dark,
          defaultDepartureCity: 'Kampala',
        ),
      );
    });

    test('values are stored under the settings.* keys', () async {
      final repo = await openRepository();
      await repo.saveThemeMode(AppThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SettingsLocalSource.themeModeKey), 'light');
    });

    test('saving one value leaves the others at their defaults', () async {
      final repo = await openRepository();
      await repo.saveLanguage('fr');

      final loaded = await repo.loadSettings();
      expect(loaded.languageCode, 'fr');
      expect(loaded.themeMode, AppSettings.defaults.themeMode);
      expect(
        loaded.defaultDepartureCity,
        AppSettings.defaults.defaultDepartureCity,
      );
    });

    test(
      'bad stored values fall back to defaults instead of crashing',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsLocalSource.languageKey: 'de',
          SettingsLocalSource.themeModeKey: 'purple',
        });
        final repo = await openRepository();

        final loaded = await repo.loadSettings();
        expect(loaded.languageCode, 'en');
        expect(loaded.themeMode, AppThemeMode.system);
      },
    );
  });

  group('SettingsCubit', () {
    late SettingsRepositoryImpl savedRepo;

    blocTest<SettingsCubit, SettingsState>(
      'load emits the saved settings',
      setUp: () async {
        SharedPreferences.setMockInitialValues({
          SettingsLocalSource.languageKey: 'sw',
        });
        savedRepo = await openRepository();
      },
      build: () => SettingsCubit(savedRepo),
      act: (cubit) => cubit.load(),
      expect: () => [
        SettingsState(
          settings: AppSettings.defaults.copyWith(languageCode: 'sw'),
          loaded: true,
        ),
      ],
    );

    test('changing the theme updates state and is saved', () async {
      final repo = await openRepository();
      final cubit = SettingsCubit(repo);

      await cubit.changeThemeMode(AppThemeMode.dark);

      expect(cubit.state.themeMode, ThemeMode.dark);
      expect((await repo.loadSettings()).themeMode, AppThemeMode.dark);
      await cubit.close();
    });

    test('an unsupported language is ignored', () async {
      final cubit = SettingsCubit(await openRepository());

      await cubit.changeLanguage('de');

      expect(cubit.state.settings.languageCode, 'en');
      await cubit.close();
    });

    test('a blank city is ignored and names are trimmed', () async {
      final repo = await openRepository();
      final cubit = SettingsCubit(repo);

      await cubit.changeDefaultDepartureCity('   ');
      expect(cubit.state.settings.defaultDepartureCity, 'Kigali');

      await cubit.changeDefaultDepartureCity('  Nairobi ');
      expect((await repo.loadSettings()).defaultDepartureCity, 'Nairobi');
      await cubit.close();
    });
  });
}
