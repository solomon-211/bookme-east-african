import 'package:equatable/equatable.dart';

enum AppThemeMode { light, dark, system }

// User preferences kept on the device (language, theme, home city).
class AppSettings extends Equatable {
  final String languageCode;
  final AppThemeMode themeMode;
  final String defaultDepartureCity; // pre-fills "From" on the search screen

  const AppSettings({
    required this.languageCode,
    required this.themeMode,
    required this.defaultDepartureCity,
  });

  // First launch, before the user has changed anything.
  static const defaults = AppSettings(
    languageCode: 'en',
    themeMode: AppThemeMode.system,
    defaultDepartureCity: 'Kigali',
  );

  // English, Français, Kiswahili, Kinyarwanda - same order as the Account chips.
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
