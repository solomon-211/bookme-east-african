import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_palette.dart';
import 'settings_cubit.dart';
import 'settings_state.dart';

// Row showing the saved home city. Tapping it opens a list of cities;
// the choice pre-fills "From" on the search screen.
class DepartureCityPicker extends StatelessWidget {
  const DepartureCityPicker({super.key});

  static const cities = [
    'Kigali',
    'Musanze',
    'Huye',
    'Kampala',
    'Nairobi',
    'Juba',
    'Dar es Salaam',
    'Bujumbura',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (a, b) =>
          a.settings.defaultDepartureCity != b.settings.defaultDepartureCity,
      builder: (context, state) {
        return InkWell(
          key: const Key('departure_city_row'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pickCity(context, state.settings.defaultDepartureCity),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.place_outlined, size: 20, color: palette.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default departure city',
                        style: TextStyle(fontSize: 12.5, color: palette.muted),
                      ),
                      Text(
                        state.settings.defaultDepartureCity,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: palette.muted),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickCity(BuildContext context, String current) async {
    final cubit = context.read<SettingsCubit>();
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Where do you usually leave from?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            for (final city in cities)
              ListTile(
                title: Text(city),
                trailing: city == current
                    ? const Icon(Icons.check_circle, size: 20)
                    : null,
                onTap: () => Navigator.pop(context, city),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await cubit.changeDefaultDepartureCity(picked);
  }
}
