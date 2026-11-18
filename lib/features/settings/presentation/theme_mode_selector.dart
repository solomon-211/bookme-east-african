import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/choice_pill.dart';
import '../domain/app_settings.dart';
import 'settings_cubit.dart';
import 'settings_state.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  static const _labels = {
    AppThemeMode.light: 'Light',
    AppThemeMode.dark: 'Dark',
    AppThemeMode.system: 'Same as phone',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (a, b) => a.settings.themeMode != b.settings.themeMode,
      builder: (context, state) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mode in AppThemeMode.values)
              ChoicePill(
                key: Key('theme_${mode.name}'),
                label: _labels[mode]!,
                selected: state.settings.themeMode == mode,
                onTap: () =>
                    context.read<SettingsCubit>().changeThemeMode(mode),
              ),
          ],
        );
      },
    );
  }
}
