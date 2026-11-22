import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/presentation/cubits/waitlist_cubit.dart';
import 'package:bookme_summative_project/features/search/presentation/search_navigation.dart';

/// Screen 5: join the waitlist for a fully booked bus, then
/// "You're on the list."
Future<void> showWaitlistDialog(BuildContext context, BusTrip trip) {
  final cubit = context.read<WaitlistCubit>();
  final navigation = context.read<SearchNavigation>();
  final phone = SearchNavigation.currentPhone(context);
  return showDialog<void>(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        RepositoryProvider<SearchNavigation>.value(value: navigation),
        BlocProvider<WaitlistCubit>.value(value: cubit),
      ],
      child: WaitlistDialog(
        trip: trip,
        initialPhone: phone,
        // Uses the page's context: the dialog's is gone once it closes.
        onManageAlerts: () {
          if (context.mounted) navigation.openAlerts(context);
        },
      ),
    ),
  );
}

class WaitlistDialog extends StatefulWidget {
  const WaitlistDialog({
    required this.trip,
    required this.onManageAlerts,
    this.initialPhone = '',
    super.key,
  });

  final BusTrip trip;
  final String initialPhone;
  final VoidCallback onManageAlerts;

  @override
  State<WaitlistDialog> createState() => _WaitlistDialogState();
}

class _WaitlistDialogState extends State<WaitlistDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.initialPhone);
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _joined = context.read<WaitlistCubit>().state.isOnWaitlist(widget.trip.id);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final entry = await context.read<WaitlistCubit>().join(widget.trip, _phone.text);
    if (entry != null && mounted) {
      setState(() {
        _joined = true;
        _phone.text = Formatters.phone(entry.phone);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final trip = widget.trip;
    final busy = context.select(
      (WaitlistCubit c) => c.state.busyTripId == trip.id,
    );
    final error = context.select((WaitlistCubit c) => c.state.errorMessage);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
                  child: Icon(
                    _joined ? Icons.notifications_active : Icons.notifications_none,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  _joined ? 'You\'re on the list.' : 'Get a seat alert',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: palette.text),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _joined
                    ? 'We\'ll notify you if a seat opens on ${trip.operatorName}. '
                        'An alert doesn\'t reserve a seat.'
                    : 'This bus is fully booked. We\'ll text you if a seat opens. '
                        'Joining doesn\'t reserve a seat.',
                style: TextStyle(color: palette.muted),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.iconTile,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${trip.origin} → ${trip.destination}',
                        style: TextStyle(fontWeight: FontWeight.w700, color: palette.text)),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.shortDate(trip.departure)} · '
                      '${Formatters.time(trip.departure)} → ${Formatters.time(trip.arrival)}',
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                    Text(
                      '${trip.operatorName} · ${Formatters.money(trip.total, trip.currency)}',
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                readOnly: _joined,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: const InputDecoration(
                  labelText: 'SMS notification number',
                  hintText: '+250 78 123 4412',
                  prefixIcon: Icon(Icons.sms_outlined),
                ),
                validator: WaitlistCubit.validatePhone,
                onFieldSubmitted: (_) => _join(),
              ),
              if (error != null && !_joined) ...[
                const SizedBox(height: 8),
                Text(error, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              if (_joined) ...[
                PrimaryButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onManageAlerts();
                  },
                  child: const Text('Manage in Alerts'),
                ),
              ] else ...[
                PrimaryButton(
                  label: 'Notify me',
                  icon: Icons.notifications_none,
                  loading: busy,
                  onPressed: _join,
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Not now'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
