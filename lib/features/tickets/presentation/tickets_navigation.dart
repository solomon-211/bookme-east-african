import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/my_trips_page.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/offline_ticket_page.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/ready_for_journey_page.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/ticket_page.dart';

/// Connects the Tickets & Trips screens to each other and to the rest of
/// the app. Other features only pass in what they own:
///
/// * [onFindBus]: open Search (My Trips empty state).
/// * [onOpenEscrowInfo]: open "Where your money is".
///
/// Either can be left out; the screen then explains where to go instead.
class TicketsNavigation {
  const TicketsNavigation({this.onFindBus, this.onOpenEscrowInfo, this.clock});

  final void Function(BuildContext context)? onFindBus;
  final void Function(BuildContext context, Ticket ticket)? onOpenEscrowInfo;
  final DateTime Function()? clock;

  DateTime get _now => (clock ?? DateTime.now)();

  /// For Booking & Payment's "View My Digital Ticket". Replaces the receipt
  /// so "back" from the ticket never returns to the paid checkout.
  void openAfterPayment(BuildContext context, Booking booking) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => _ticketPage(booking.id)),
    );
  }

  MyTripsActions get myTripsActions => MyTripsActions(
    onShowTicket: (context, ticket) => ticket.isUpcoming(_now)
        ? openOfflineQr(context, ticket)
        : openTicket(context, ticket.id),
    onManage: openManage,
    onOpenChecklist: openReadyForJourney,
    onFindBus: _findBus,
  );

  void openTicket(BuildContext context, String bookingId) {
    _push(context, _ticketPage(bookingId));
  }

  void openOfflineQr(BuildContext context, Ticket ticket) {
    _push(
      context,
      OfflineTicketPage(
        bookingId: ticket.id,
        ticket: ticket,
        onOpenFullTicket: (ctx, t) => openTicket(ctx, t.id),
      ),
    );
  }

  void openReadyForJourney(BuildContext context, Ticket ticket) {
    _push(
      context,
      ReadyForJourneyPage(
        ticket: ticket,
        clock: clock,
        actions: ReadyForJourneyActions(
          onShowOfflineQr: openOfflineQr,
          onManage: openManage,
        ),
      ),
    );
  }

  /// Manage Booking is built on Day 3; until then this explains it.
  void openManage(BuildContext context, Ticket ticket) {
    _push(
      context,
      const _NotReadyPage(
        title: 'Manage Booking',
        message:
            'Changing the date or cancelling this booking will be available '
            'here soon.',
      ),
    );
  }

  Widget _ticketPage(String bookingId) => TicketPage(
    bookingId: bookingId,
    actions: TicketActions(
      onOpenChecklist: openReadyForJourney,
      onOpenEscrowInfo: _escrowInfo,
    ),
  );

  void _findBus(BuildContext context) {
    final open = onFindBus;
    if (open != null) return open(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open the Search tab to find a bus.')),
    );
  }

  void _escrowInfo(BuildContext context, Ticket ticket) {
    final open = onOpenEscrowInfo;
    if (open != null) return open(context, ticket);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'BookMe holds your payment in escrow and releases it to the '
          'operator only after verified boarding.',
        ),
      ),
    );
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _NotReadyPage extends StatelessWidget {
  const _NotReadyPage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}
