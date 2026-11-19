import 'dart:async';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';

/// Same behaviour as the Firestore tickets data source, without a server.
///
/// Used by widget and cubit tests, and to work on the screens before
/// Firebase is configured. Like `snapshots()`, every stream first emits the
/// current value and then emits again after each [put] or [remove].
class InMemoryTicketsDataSource implements TicketsDataSource {
  InMemoryTicketsDataSource({
    this.userId = 'demo-user',
    Iterable<Ticket> initial = const [],
  }) {
    for (final ticket in initial) {
      _tickets[ticket.id] = ticket;
    }
  }

  /// Plays the role of the Firebase Auth uid.
  final String userId;

  final Map<String, Ticket> _tickets = {};

  /// Refunds recorded by [cancelBooking], by booking id.
  final Map<String, RefundQuote> refunds = {};

  /// Seats freed by [cancelBooking], as `tripId/seatNumber`.
  final Set<String> freedSeats = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Adds or replaces a ticket, like writing the booking document.
  void put(Ticket ticket) {
    _tickets[ticket.id] = ticket;
    _changes.add(null);
  }

  /// Removes a ticket, like deleting the booking document.
  void remove(String bookingId) {
    _tickets.remove(bookingId);
    _changes.add(null);
  }

  @override
  Future<void> cancelBooking(Ticket ticket, RefundQuote refund) async {
    final current = _tickets[ticket.id];
    if (current == null || !current.isPaid) {
      throw const BookingFailure(
        'This booking was already cancelled or changed.',
      );
    }
    refunds[ticket.id] = refund;
    freedSeats.add('${current.booking.tripId}/${current.booking.seatNumber}');
    put(
      Ticket(
        booking: current.booking.copyWith(status: BookingStatus.cancelled),
        trip: current.trip,
        tripStatus: current.tripStatus,
      ),
    );
  }

  @override
  Future<void> deleteBooking(String bookingId) async => remove(bookingId);

  @override
  Stream<List<Ticket>> watchMyTickets() => _watch(_myTickets);

  @override
  Stream<Ticket> watchTicket(String bookingId) =>
      _watch(() => _tickets[bookingId])
          .where((ticket) => ticket != null)
          .cast<Ticket>()
          .distinct();

  /// Same filter and order as the Firestore query.
  List<Ticket> _myTickets() {
    final tickets = _tickets.values
        .where(
          (t) =>
              t.booking.userId == userId &&
              Ticket.listedStatuses.contains(t.booking.status),
        )
        .toList();
    tickets.sort((a, b) => b.trip.departure.compareTo(a.trip.departure));
    return tickets;
  }

  Stream<T> _watch<T>(T Function() read) {
    late final StreamController<T> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        sub = _changes.stream.listen((_) => controller.add(read()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  Future<void> dispose() => _changes.close();
}
