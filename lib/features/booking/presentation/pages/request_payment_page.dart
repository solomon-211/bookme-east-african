import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/utils/booking_reference.dart';
import 'package:bookme_summative_project/features/booking/domain/validators/passenger_validators.dart';
import 'package:bookme_summative_project/features/booking/presentation/booking_flow.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/passenger_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/payment_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/seat_hold_cubit.dart';
import 'package:bookme_summative_project/features/booking/presentation/pages/approve_on_phone_page.dart';
import 'package:bookme_summative_project/features/booking/presentation/pages/pay_for_seat_page.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/booking_text_field.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/flow_scaffold.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/hold_expiry_guard.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/info_note.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/toggle_card.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/trip_summary_card.dart';

/// Screen 2 of 5 (alternative path): "Someone else is paying".
///
/// Sends the payer a secure link by SMS. The seat stays reserved for 30
/// minutes while they pay, and the ticket still belongs to the passenger.
class RequestPaymentPage extends StatefulWidget {
  const RequestPaymentPage({super.key});

  @override
  State<RequestPaymentPage> createState() => _RequestPaymentPageState();
}

class _RequestPaymentPageState extends State<RequestPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _payerPhone = TextEditingController();

  @override
  void dispose() {
    _payerPhone.dispose();
    super.dispose();
  }

  void _send() {
    final booking = context.read<SeatHoldCubit>().state.booking;
    if (booking == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<PaymentCubit>().requestFromSomeoneElse(
      booking: booking,
      payerPhone: _payerPhone.text,
    );
  }

  /// Turning the switch off swaps this screen for the normal Pay screen.
  void _payMyself() {
    context.read<PassengerCubit>().setSomeoneElsePaying(false);
    BookingFlow.replace<void>(context, const PayForSeatPage());
  }

  Future<void> _copyLink(String link) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: link));
    messenger.showSnackBar(
      const SnackBar(content: Text('Payment link copied.')),
    );
  }

  /// Opens the SMS app with the message ready to send. If the phone has no
  /// SMS app the request still works: the payer can use the copied link.
  Future<void> _openSms(Booking booking, String payerPhone) async {
    final trip = context.read<BookingFlowArgs>().trip;
    final passenger =
        context.read<PassengerCubit>().state.passenger?.fullName ??
        'A traveller';
    final message =
        '$passenger asked you to pay '
        '${Formatters.money(booking.totalAmount, booking.currency)} for a '
        '${trip.operatorName} ticket (${trip.fromCode} → ${trip.toCode}). '
        'Pay securely here: ${buildPaymentLink(booking.reference)}';
    final uri = Uri(
      scheme: 'sms',
      path: PassengerValidators.normalizePhone(payerPhone),
      query: 'body=${Uri.encodeComponent(message)}',
    );
    try {
      await launchUrl(uri);
    } catch (_) {
      // No SMS app (e.g. some emulators); the link can still be shared.
    }
  }

  Future<void> _onPaymentChanged(
    BuildContext context,
    PaymentState state,
  ) async {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (state.message != null && state.status == PaymentFlowStatus.idle) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.message!)));
      return;
    }
    final booking = context.read<SeatHoldCubit>().state.booking;
    if (state.status == PaymentFlowStatus.awaitingApproval &&
        state.isRequest &&
        booking != null) {
      await _openSms(booking, _payerPhone.text);
      if (!context.mounted) return;
      BookingFlow.push<void>(context, const ApproveOnPhonePage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.read<BookingFlowArgs>().trip;
    final total = Formatters.money(trip.total, trip.currency);
    final booking = context.select<SeatHoldCubit, Booking?>(
      (cubit) => cubit.state.booking,
    );
    final holdActive = context.select<SeatHoldCubit, bool>(
      (cubit) => cubit.state.status == SeatHoldStatus.active,
    );
    final passengerName =
        context.read<PassengerCubit>().state.passenger?.fullName ?? 'you';
    final link = booking == null ? '' : buildPaymentLink(booking.reference);
    final textTheme = Theme.of(context).textTheme;

    return HoldExpiryGuard(
      child: BlocConsumer<PaymentCubit, PaymentState>(
        listenWhen: (p, c) => p.status != c.status || p.message != c.message,
        listener: _onPaymentChanged,
        builder: (context, state) => FlowScaffold(
          title: 'Request payment',
          bottom: PrimaryButton(
            key: const ValueKey('send-request'),
            label: 'Send Payment Request by SMS',
            icon: Icons.sms_outlined,
            loading: state.status == PaymentFlowStatus.submitting,
            onPressed: holdActive ? _send : null,
          ),
          children: [
            ToggleCard(
              title: 'Someone else is paying',
              subtitle: 'The ticket still belongs to $passengerName.',
              value: true,
              onChanged: (_) => _payMyself(),
            ),
            const SizedBox(height: 12),
            TripSummaryCard(
              trip: trip,
              seatNumber: booking?.seatNumber,
              footer: Text(
                'Total to pay · $total',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            InfoNote(
              tone: InfoNoteTone.highlight,
              icon: Icons.timer_outlined,
              title: 'Payment request valid for 30:00',
              message:
                  'Seat ${booking?.seatNumber ?? ''} stays reserved '
                  'during this request.',
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: BookingTextField(
                fieldKey: const ValueKey('payer-phone'),
                label: 'Payer\'s phone number',
                controller: _payerPhone,
                hint: '+250 78 555 0198',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: PassengerValidators.phone,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share a secure payment request',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    link,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Copy Payment Link',
                    icon: Icons.copy_rounded,
                    style: PrimaryButtonStyle.outlined,
                    onPressed: link.isEmpty ? null : () => _copyLink(link),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The payer can use mobile money or card. Funds stay in escrow '
              'until your successful, verified boarding. You\'ll both '
              'receive confirmation.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
