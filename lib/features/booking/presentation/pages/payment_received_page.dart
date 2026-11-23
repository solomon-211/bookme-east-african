import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';
import 'package:bookme_summative_project/features/booking/presentation/booking_flow.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/flow_scaffold.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/info_note.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/trip_summary_card.dart';

/// Screen 5 of 5: the receipt.
///
/// It gets everything it needs through the constructor because the booking
/// screens (and their cubits) have already been removed from the back stack.
class PaymentReceivedPage extends StatelessWidget {
  const PaymentReceivedPage({
    required this.args,
    required this.booking,
    required this.payment,
    super.key,
  });

  final BookingFlowArgs args;
  final Booking booking;
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final trip = args.trip;
    final textTheme = Theme.of(context).textTheme;
    final amount = Formatters.money(payment.amount, payment.currency);
    final paidWith = payment.method.needsPhone
        ? '${payment.method.label} ${payment.maskedPhone}'
        : payment.method.label;

    return FlowScaffold(
      title: 'Payment received',
      subtitle: booking.reference,
      bottom: PrimaryButton(
        key: const ValueKey('view-ticket'),
        label: 'View My Digital Ticket',
        icon: Icons.qr_code_2_rounded,
        onPressed: () => args.onViewTicket(context, booking),
      ),
      children: [
        const SizedBox(height: 16),
        const Center(child: _SuccessBadge()),
        const SizedBox(height: 20),
        Text(
          'Paid. Protected.\nReady to go.',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.palette.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your guaranteed seat ${booking.seatNumber} is confirmed. '
          'We\'ve sent a receipt by SMS.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: context.palette.muted),
        ),
        const SizedBox(height: 20),
        TripSummaryCard(
          trip: trip,
          seatNumber: booking.seatNumber,
          dark: false,
          footer: Column(
            children: [
              _ReceiptRow(label: 'Paid with', value: paidWith),
              const SizedBox(height: 6),
              _ReceiptRow(label: 'Amount received', value: amount, bold: true),
              if (payment.paidByOther) ...[
                const SizedBox(height: 6),
                const _ReceiptRow(label: 'Paid by', value: 'Payment request'),
              ],
            ],
          ),
        ),
        InfoNote(
          title: 'Your money. Protected.',
          message:
              'BookMe holds $amount in escrow. Funds are released ONLY '
              'after successful, verified boarding.',
        ),
        const SizedBox(height: 12),
        Text(
          'Payment complete · Hold timer closed\n'
          'No money has been released to the operator yet.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: AppColors.success),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(color: context.palette.muted),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: style?.copyWith(
              color: context.palette.text,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Lime check mark that pops in once when the screen opens.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Semantics(
        label: 'Payment successful',
        child: Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppColors.lime,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 48,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}
