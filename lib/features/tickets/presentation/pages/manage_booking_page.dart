import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/info_note.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/manage_booking_cubit.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/menu_tile.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/page_header.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/trip_route_row.dart';

/// Where the rows on Manage Booking lead. Wired in by `TicketsNavigation`.
class ManageBookingActions {
  const ManageBookingActions({
    required this.onChangeDate,
    required this.onOpenEscrowInfo,
  });

  /// "Change date / time". Completes with the moved booking, or `null` if
  /// the traveller went back without changing it.
  final Future<Ticket?> Function(BuildContext context, Ticket ticket)
  onChangeDate;

  /// "Where your money is".
  final void Function(BuildContext context, Ticket ticket) onOpenEscrowInfo;
}

/// Manage Booking: change the departure, cancel with a refund, or remove a
/// finished trip from history. Needs a [TicketsRepository] above it.
class ManageBookingPage extends StatelessWidget {
  const ManageBookingPage({
    required this.ticket,
    required this.actions,
    this.clock,
    super.key,
  });

  final Ticket ticket;
  final ManageBookingActions actions;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ManageBookingCubit(
        repository: ctx.read<TicketsRepository>(),
        ticket: ticket,
        clock: clock,
      ),
      child: ManageBookingView(actions: actions, clock: clock),
    );
  }
}

/// The screen itself, separate from [ManageBookingPage] so tests can supply
/// their own cubit.
class ManageBookingView extends StatelessWidget {
  const ManageBookingView({required this.actions, this.clock, super.key});

  final ManageBookingActions actions;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManageBookingCubit, ManageBookingState>(
      listenWhen: (before, after) =>
          before.status != after.status || before.message != after.message,
      listener: (context, state) {
        if (state.status == ManageBookingStatus.removed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip removed from your history.')),
          );
          Navigator.of(context).maybePop();
          return;
        }
        final message = state.message;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<ManageBookingCubit>();
        final ticket = state.ticket;
        final now = (clock ?? DateTime.now)();
        final passenger = ticket.booking.passenger?.fullName;
        final paid = Formatters.money(
          ticket.booking.totalAmount,
          ticket.booking.currency,
        );

        return Scaffold(
          backgroundColor: context.palette.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Manage booking',
                  subtitle: passenger == null
                      ? ticket.booking.reference
                      : '${ticket.booking.reference} · $passenger',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      _TripCard(ticket: ticket),
                      if (ticket.canManage(now)) ...[
                        const SizedBox(height: 16),
                        MenuTile(
                          icon: Icons.calendar_month_outlined,
                          title: 'Change date / time',
                          subtitle:
                              'See available departures and any fare '
                              'difference before confirming.',
                          onTap: () => _changeDate(context, ticket),
                        ),
                      ],
                      if (state.quote case final quote?) ...[
                        const SizedBox(height: 16),
                        _RefundCard(
                          quote: quote,
                          currency: ticket.booking.currency,
                          working: state.isWorking,
                          onCancel: () =>
                              _confirmCancel(context, ticket, quote),
                        ),
                      ],
                      if (ticket.isCancelled) ...[
                        const SizedBox(height: 16),
                        _CancelledCard(
                          refunded: state.refunded,
                          currency: ticket.booking.currency,
                        ),
                      ],
                      if (cubit.canRemove) ...[
                        const SizedBox(height: 16),
                        _RemoveCard(
                          working: state.isWorking,
                          onRemove: () => _confirmRemove(context),
                        ),
                      ],
                      const SizedBox(height: 16),
                      MenuTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Where your money is',
                        subtitle: ticket.isPaid
                            ? '$paid · Protected in escrow'
                            : 'Refund and payment details',
                        onTap: () => actions.onOpenEscrowInfo(context, ticket),
                      ),
                      if (ticket.isPaid) ...[
                        const SizedBox(height: 16),
                        InfoNote(
                          title: 'Your money. Protected.',
                          icon: Icons.lock_outline_rounded,
                          message:
                              'BookMe holds $paid in escrow. Funds are '
                              'released ONLY after successful, verified '
                              'boarding.',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeDate(BuildContext context, Ticket ticket) async {
    final cubit = context.read<ManageBookingCubit>();
    final changed = await actions.onChangeDate(context, ticket);
    if (changed != null) cubit.ticketChanged(changed);
  }

  Future<void> _confirmCancel(
    BuildContext context,
    Ticket ticket,
    RefundQuote quote,
  ) async {
    final cubit = context.read<ManageBookingCubit>();
    final refund = Formatters.money(quote.refund, ticket.booking.currency);
    final confirmed = await _confirm(
      context,
      title: 'Cancel this booking?',
      message: quote.refund > 0
          ? '$refund goes back to your original payment method and seat '
                '${ticket.booking.seatNumber} is released. This can\'t be '
                'undone.'
          : 'No refund is due this close to departure. Seat '
                '${ticket.booking.seatNumber} is released. This can\'t be '
                'undone.',
      keepLabel: 'Keep booking',
      confirmLabel: 'Cancel booking',
    );
    if (confirmed) await cubit.cancel();
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final cubit = context.read<ManageBookingCubit>();
    final confirmed = await _confirm(
      context,
      title: 'Remove this trip?',
      message:
          'It is deleted from My Trips on every device signed in to your '
          'account. This can\'t be undone.',
      keepLabel: 'Keep it',
      confirmLabel: 'Remove',
    );
    if (confirmed) await cubit.remove();
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String keepLabel,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(keepLabel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final trip = ticket.trip;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TripRouteRow(trip: trip, dark: true),
          const SizedBox(height: 8),
          Text(
            '${Formatters.shortDate(trip.departure)} → '
            '${Formatters.shortDate(trip.arrival)} · '
            '${trip.operatorName} · Seat ${ticket.booking.seatNumber}',
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF969FA2),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Cancel / request refund" with the refund worked out before confirming.
class _RefundCard extends StatelessWidget {
  const _RefundCard({
    required this.quote,
    required this.currency,
    required this.working,
    required this.onCancel,
  });

  final RefundQuote quote;
  final String currency;
  final bool working;
  final VoidCallback onCancel;

  String get _policy => switch (quote.reason) {
    RefundReason.operatorCancelled =>
      'The operator cancelled this trip, so everything you paid is refunded.',
    RefundReason.longDelay =>
      'This departure is delayed more than 2 hours, so everything you paid '
          'is refunded.',
    RefundReason.voluntary =>
      'Cancelling yourself: the service fee is kept, and less of the fare '
          'is refunded within 24 hours of departure.',
  };

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      children: [
        const _CardTitle('Cancel / request refund'),
        Text(
          '100% refund for operator cancellations or delays over 2 hours. '
          '$_policy',
          style: _bodyStyle(context),
        ),
        _AmountRow(
          label: 'Original payment',
          amount: Formatters.money(quote.paid, currency),
        ),
        _AmountRow(
          label: 'You get back',
          amount: Formatters.money(quote.refund, currency),
          color: AppColors.success,
        ),
        Text(
          'Refunds go back to the original mobile money number or card.',
          style: _noteStyle(context),
        ),
        _DangerButton(
          label: 'Cancel / Request Refund',
          working: working,
          onPressed: onCancel,
        ),
      ],
    );
  }
}

class _CancelledCard extends StatelessWidget {
  const _CancelledCard({required this.refunded, required this.currency});

  final RefundQuote? refunded;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final refund = refunded;
    return _WhiteCard(
      children: [
        const _CardTitle('Booking cancelled'),
        Text(
          refund == null
              ? 'Any refund goes back to the original payment method.'
              : refund.refund > 0
              ? '${Formatters.money(refund.refund, currency)} is on its way '
                    'back to the original payment method. Processing time '
                    'depends on the payment provider.'
              : 'No refund was due for this cancellation.',
          style: _bodyStyle(context),
        ),
      ],
    );
  }
}

class _RemoveCard extends StatelessWidget {
  const _RemoveCard({required this.working, required this.onRemove});

  final bool working;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      children: [
        const _CardTitle('Remove from history'),
        Text(
          'Deletes this trip from My Trips. Upcoming trips have to be '
          'cancelled first.',
          style: _bodyStyle(context),
        ),
        _DangerButton(
          label: 'Remove from History',
          working: working,
          onPressed: onRemove,
        ),
      ],
    );
  }
}

TextStyle _bodyStyle(BuildContext context) =>
    TextStyle(fontSize: 12, height: 1.4, color: context.palette.muted);

TextStyle _noteStyle(BuildContext context) =>
    TextStyle(fontSize: 11, height: 1.4, color: context.palette.muted);

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: children,
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: context.palette.text,
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.amount, this.color});

  final String label;
  final String amount;

  /// Defaults to the theme's text colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: context.palette.text),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color ?? context.palette.text,
          ),
        ),
      ],
    );
  }
}

/// White pill with red text, for actions that can't be undone.
class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.working,
    required this.onPressed,
  });

  final String label;
  final bool working;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: working ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          backgroundColor: context.palette.card,
          side: BorderSide(color: context.palette.border),
          shape: const StadiumBorder(),
        ),
        child: working
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.error,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
