import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/choice_pill.dart';
import '../domain/app_settings.dart';
import 'settings_cubit.dart';
import 'settings_state.dart';

// The "Language / Langue" chips on the Account screen.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  // Each language is written in its own language, so people can find theirs.
  static const languageNames = {
    'en': 'English',
    'fr': 'Français',
    'sw': 'Kiswahili',
    'rw': 'Kinyarwanda',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (a, b) => a.settings.languageCode != b.settings.languageCode,
      builder: (context, state) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in AppSettings.supportedLanguages)
              ChoicePill(
                key: Key('language_$code'),
                label: languageNames[code]!,
                selected: state.settings.languageCode == code,
                onTap: () => context.read<SettingsCubit>().changeLanguage(code),
              ),
          ],
        );
      },
    );
  }
}
