import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/passenger.dart';
import 'package:bookme_summative_project/features/booking/domain/validators/passenger_validators.dart';
import 'package:bookme_summative_project/features/booking/presentation/booking_flow.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/passenger_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/seat_hold_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/pages/pay_for_seat_page.dart';
import 'package:bookme_summative_project/features/booking/presentation/pages/request_payment_page.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/booking_text_field.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/flow_scaffold.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/hold_expiry_guard.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/hold_timer_banner.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/info_note.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/toggle_card.dart';

/// Screen 1 of 5: passenger details for the border manifest.
///
/// This is a StatefulWidget only to own the text controllers and form key.
/// All app state (saving, who pays, errors) lives in [PassengerCubit].
class WhosTravellingPage extends StatefulWidget {
  const WhosTravellingPage({super.key});

  static const List<String> nationalities = [
    'Rwanda',
    'Uganda',
    'Kenya',
    'Tanzania',
    'Burundi',
    'South Sudan',
    'DR Congo',
    'Other',
  ];

  @override
  State<WhosTravellingPage> createState() => _WhosTravellingPageState();
}

class _WhosTravellingPageState extends State<WhosTravellingPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final TextEditingController _phone;
  final _email = TextEditingController();
  final _idNumber = TextEditingController();
  String? _nationality;

  @override
  void initState() {
    super.initState();
    final args = context.read<BookingFlowArgs>();
    _phone = TextEditingController(text: args.initialPhone);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  void _submit() {
    final booking = context.read<SeatHoldCubit>().state.booking;
    if (booking == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }
    final email = _email.text.trim();
    context.read<PassengerCubit>().submit(
      bookingId: booking.id,
      passenger: Passenger(
        fullName: _name.text.trim().replaceAll(RegExp(r'\s+'), ' '),
        phone: PassengerValidators.normalizePhone(_phone.text),
        idNumber: _idNumber.text.replaceAll(' ', '').toUpperCase(),
        nationality: _nationality!,
        email: email.isEmpty ? null : email,
      ),
    );
  }

  void _onPassengerChanged(BuildContext context, PassengerState state) {
    if (state.message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message!)));
      return;
    }
    if (state.status == PassengerFormStatus.saved) {
      BookingFlow.push<void>(
        context,
        state.someoneElsePaying
            ? const RequestPaymentPage()
            : const PayForSeatPage(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = context.read<BookingFlowArgs>();
    return HoldExpiryGuard(
      child: BlocListener<PassengerCubit, PassengerState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.message != current.message,
        listener: _onPassengerChanged,
        child: BlocBuilder<SeatHoldCubit, SeatHoldState>(
          // The countdown banner rebuilds itself every second; the form
          // only needs to rebuild when the hold status changes.
          buildWhen: (previous, current) => previous.status != current.status,
          builder: (context, hold) {
            if (hold.status == SeatHoldStatus.failure) {
              return _HoldFailed(message: hold.message);
            }
            return FlowScaffold(
              title: 'Who\'s travelling?',
              subtitle:
                  '${args.trip.fromCode} → ${args.trip.toCode} · '
                  '${args.trip.operatorName}',
              bottom: BlocBuilder<PassengerCubit, PassengerState>(
                buildWhen: (p, c) => p.status != c.status,
                builder: (context, passenger) => PrimaryButton(
                  key: const ValueKey('continue-to-payment'),
                  label: 'Continue to Payment',
                  icon: Icons.arrow_forward,
                  loading: passenger.status == PassengerFormStatus.saving,
                  onPressed: hold.status == SeatHoldStatus.active
                      ? _submit
                      : null,
                ),
              ),
              children: [
                const HoldTimerBanner(
                  title: 'Your seat has been held for 10 minutes',
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BookingTextField(
                          fieldKey: const ValueKey('field-name'),
                          label: 'Full name · Must match your document',
                          controller: _name,
                          hint: 'e.g. Moses Mugisha',
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.name],
                          validator: PassengerValidators.fullName,
                        ),
                        BookingTextField(
                          fieldKey: const ValueKey('field-phone'),
                          label: 'Phone · Ticket and travel alerts',
                          controller: _phone,
                          hint: '+250 78 123 4412',
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          validator: PassengerValidators.phone,
                        ),
                        BookingTextField(
                          fieldKey: const ValueKey('field-email'),
                          label: 'Email · Receipt copy (optional)',
                          controller: _email,
                          hint: 'moses.mugisha@example.com',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: PassengerValidators.optionalEmail,
                        ),
                        BookingTextField(
                          fieldKey: const ValueKey('field-id'),
                          label: 'Passport / EAC ID number',
                          controller: _idNumber,
                          hint: '1199 8800 4412 0036',
                          helper:
                              'Only shared with the operator for the '
                              'border manifest.',
                          textCapitalization: TextCapitalization.characters,
                          validator: PassengerValidators.idNumber,
                        ),
                        _NationalityField(
                          value: _nationality,
                          onChanged: (value) => _nationality = value,
                        ),
                      ],
                    ),
                  ),
                ),
                const _SomeoneElsePayingCard(),
                const InfoNote(
                  tone: InfoNoteTone.caution,
                  icon: Icons.badge_outlined,
                  message:
                      'Check passport, EAC ID and entry requirements '
                      'before travel. Document acceptance depends on '
                      'nationality.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NationalityField extends StatelessWidget {
  const _NationalityField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nationality',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const ValueKey('field-nationality'),
          initialValue: value,
          isExpanded: true,
          hint: const Text('Choose nationality'),
          decoration: bookingInputDecoration(prefixIcon: Icons.flag_outlined),
          items: [
            for (final country in WhosTravellingPage.nationalities)
              DropdownMenuItem(value: country, child: Text(country)),
          ],
          validator: PassengerValidators.nationality,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SomeoneElsePayingCard extends StatelessWidget {
  const _SomeoneElsePayingCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PassengerCubit, PassengerState>(
      buildWhen: (p, c) => p.someoneElsePaying != c.someoneElsePaying,
      builder: (context, state) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: ToggleCard(
          switchKey: const ValueKey('someone-else-paying'),
          title: 'Someone else is paying',
          subtitle: 'Send a secure 30-minute payment request by link or SMS.',
          value: state.someoneElsePaying,
          onChanged: context.read<PassengerCubit>().setSomeoneElsePaying,
        ),
      ),
    );
  }
}

/// Shown instead of the form when no seat could be held.
class _HoldFailed extends StatelessWidget {
  const _HoldFailed({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return FlowScaffold(
      title: 'Who\'s travelling?',
      bottom: PrimaryButton(
        label: 'Back to trip',
        onPressed: () => Navigator.of(context).pop(),
      ),
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.event_seat_outlined, size: 56, color: AppColors.muted),
        const SizedBox(height: 16),
        Text(
          message ?? 'We couldn\'t hold a seat on this bus.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
