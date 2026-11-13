import 'package:equatable/equatable.dart';

/// Theme options the user can pick on the Account screen.
enum AppThemeMode { light, dark, system }

/// The user's saved preferences, stored on the device with
/// SharedPreferences so they are restored when the app relaunches.
class AppSettings extends Equatable {
  /// 'en' English, 'fr' Français, 'sw' Kiswahili, 'rw' Kinyarwanda.
  final String languageCode;

  /// Light, dark, or follow the phone's setting.
  final AppThemeMode themeMode;

  /// City pre-filled in the "From" field on the search screen.
  final String defaultDepartureCity;

  const AppSettings({
    required this.languageCode,
    required this.themeMode,
    required this.defaultDepartureCity,
  });

  /// Values used the first time the app is opened.
  static const defaults = AppSettings(
    languageCode: 'en',
    themeMode: AppThemeMode.system,
    defaultDepartureCity: 'Kigali',
  );

  /// Supported languages, in the order shown on the Account screen.
  static const supportedLanguages = ['en', 'fr', 'sw', 'rw'];

  AppSettings copyWith({
    String? languageCode,
    AppThemeMode? themeMode,
    String? defaultDepartureCity,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      defaultDepartureCity: defaultDepartureCity ?? this.defaultDepartureCity,
    );
  }

  @override
  List<Object?> get props => [languageCode, themeMode, defaultDepartureCity];
}
