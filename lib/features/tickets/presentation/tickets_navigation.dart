import 'package:flutter/material.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/change_date_page.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/manage_booking_page.dart';
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

  void openManage(BuildContext context, Ticket ticket) {
    _push(
      context,
      ManageBookingPage(
        ticket: ticket,
        clock: clock,
        actions: ManageBookingActions(
          onChangeDate: _changeDate,
          onOpenEscrowInfo: _escrowInfo,
        ),
      ),
    );
  }

  Future<Ticket?> _changeDate(BuildContext context, Ticket ticket) =>
      Navigator.of(context).push<Ticket>(
        MaterialPageRoute(
          builder: (_) => ChangeDatePage(ticket: ticket, clock: clock),
        ),
      );

  Widget _ticketPage(String bookingId) => TicketPage(
    bookingId: bookingId,
    actions: TicketActions(
      onOpenChecklist: openReadyForJourney,
      onOpenEscrowInfo: _escrowInfo,
      onManage: openManage,
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
