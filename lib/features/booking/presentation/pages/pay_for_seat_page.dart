import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment_method.dart';
import 'package:bookme_summative_project/features/booking/domain/validators/passenger_validators.dart';
import 'package:bookme_summative_project/features/booking/presentation/booking_flow.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/payment_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/seat_hold_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/pages/approve_on_phone_page.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/booking_text_field.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/flow_scaffold.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/hold_expiry_guard.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/hold_timer_banner.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/info_note.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/payment_method_tile.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/trip_summary_card.dart';

/// Screen 3 of 5: choose a method and pay.
class PayForSeatPage extends StatefulWidget {
  const PayForSeatPage({super.key});

  @override
  State<PayForSeatPage> createState() => _PayForSeatPageState();
}

class _PayForSeatPageState extends State<PayForSeatPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final saved = context.read<PaymentCubit>().state.phone;
    _phone = TextEditingController(
      text: saved.isEmpty ? '' : Formatters.phone(saved),
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _isOnTop => ModalRoute.of(context)?.isCurrent ?? false;

  void _pay() {
    final payment = context.read<PaymentCubit>();
    final booking = context.read<SeatHoldCubit>().state.booking;
    if (booking == null) return;
    if (payment.state.method.needsPhone &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    payment.pay(booking: booking, phone: _phone.text);
  }

  void _onPaymentChanged(BuildContext context, PaymentState state) {
    // Saved preferences can arrive after the screen opens; only fill the
    // field if the traveller hasn't typed anything yet.
    if (_phone.text.isEmpty && state.phone.isNotEmpty) {
      _phone.text = Formatters.phone(state.phone);
    }
    if (!_isOnTop) return;
    if (state.message != null && state.status == PaymentFlowStatus.idle) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message!)));
    }
    if (state.status == PaymentFlowStatus.awaitingApproval) {
      BookingFlow.push<void>(context, const ApproveOnPhonePage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.read<BookingFlowArgs>().trip;
    final total = Formatters.money(trip.total, trip.currency);
    final seat = context.select<SeatHoldCubit, String?>(
      (cubit) => cubit.state.booking?.seatNumber,
    );
    final holdActive = context.select<SeatHoldCubit, bool>(
      (cubit) => cubit.state.status == SeatHoldStatus.active,
    );

    return HoldExpiryGuard(
      child: BlocConsumer<PaymentCubit, PaymentState>(
        listenWhen: (p, c) =>
            p.status != c.status ||
            p.message != c.message ||
            p.phone != c.phone,
        listener: _onPaymentChanged,
        builder: (context, state) {
          final cubit = context.read<PaymentCubit>();
          return FlowScaffold(
            title: 'Pay for your seat',
            bottom: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  key: const ValueKey('pay-button'),
                  label: 'Pay $total',
                  icon: Icons.lock_outline,
                  style: PrimaryButtonStyle.success,
                  loading: state.status == PaymentFlowStatus.submitting,
                  onPressed: holdActive ? _pay : null,
                ),
                const SizedBox(height: 6),
                Text(
                  '${Formatters.money(trip.baseFare, trip.currency)} fare'
                  '${trip.taxes > 0 ? ' + ${Formatters.money(trip.taxes, trip.currency)} taxes' : ''}'
                  ' + ${Formatters.money(trip.serviceFee, trip.currency)} '
                  'service fee. No other charges.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            children: [
              HoldTimerBanner(
                title: 'Seat ${seat ?? ''} held for 10 minutes',
                showProgress: true,
              ),
              const SizedBox(height: 12),
              TripSummaryCard(trip: trip, seatNumber: seat),
              const SectionLabel('Pay with'),
              for (final method in PaymentMethod.values)
                PaymentMethodTile(
                  method: method,
                  selected: state.method == method,
                  onTap: state.isBusy ? null : () => cubit.selectMethod(method),
                ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: state.method.needsPhone
                    ? Form(
                        key: _formKey,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: BookingTextField(
                            fieldKey: const ValueKey('payment-phone'),
                            label: 'Payment phone number',
                            controller: _phone,
                            hint: '+250 78 123 4412',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            validator: PassengerValidators.phone,
                          ),
                        ),
                      )
                    : const InfoNote(
                        tone: InfoNoteTone.highlight,
                        icon: Icons.credit_card,
                        message:
                            'You\'ll confirm the card payment with your '
                            'bank on the next screen.',
                      ),
              ),
              InfoNote(
                title: 'Your money. Protected.',
                message:
                    'BookMe holds $total in escrow. Funds are released '
                    'ONLY after successful, verified boarding.',
              ),
            ],
          );
        },
      ),
    );
  }
}
