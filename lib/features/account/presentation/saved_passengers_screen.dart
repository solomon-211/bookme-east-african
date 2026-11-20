import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/saved_passenger.dart';
import 'account_cubit.dart';
import 'account_state.dart';
import 'passenger_form_sheet.dart';

// Full list of saved passengers: add, edit and delete.
// Pushed from the Account screen, which shares its AccountCubit.
class SavedPassengersScreen extends StatelessWidget {
  const SavedPassengersScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    SavedPassenger passenger,
  ) async {
    final cubit = context.read<AccountCubit>();
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove passenger?'),
        content: Text(
          '${passenger.fullName} will no longer be suggested when you book.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes == true) await cubit.deletePassenger(passenger);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AccountCubit, AccountState>(
          builder: (context, state) {
            return ListView(
              children: [
                const PageHeader(
                  title: 'Saved passengers',
                  subtitle: 'Filled in for you when you book',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.passengers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No saved passengers yet. Add the people you '
                            'often travel with to book faster.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: palette.muted),
                          ),
                        ),
                      for (final p in state.passengers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PassengerCard(
                            passenger: p,
                            onEdit: () =>
                                showPassengerForm(context, passenger: p),
                            onDelete: () => _confirmDelete(context, p),
                          ),
                        ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        key: const Key('add_passenger'),
                        onPressed: () => showPassengerForm(context),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Add passenger'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: const StadiumBorder(),
                          foregroundColor: palette.text,
                          side: BorderSide(color: palette.border),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PassengerCard extends StatelessWidget {
  const _PassengerCard({
    required this.passenger,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedPassenger passenger;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final id = passenger.idNumber;
    final last4 = id.length <= 4 ? id : id.substring(id.length - 4);

    return SurfaceCard(
      onTap: onEdit,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passenger.fullName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.phone(passenger.phone)} · '
                  '${passenger.nationality} · ID ending $last4',
                  style: TextStyle(fontSize: 12.5, color: palette.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit ${passenger.fullName}',
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, color: palette.muted),
          ),
          IconButton(
            tooltip: 'Remove ${passenger.fullName}',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
