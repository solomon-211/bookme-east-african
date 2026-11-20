import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/date_change.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';

/// Storage for the traveller's tickets.
///
/// Implemented with Firestore by `TicketsFirestoreDataSource`.
abstract interface class TicketsDataSource {
  Stream<List<Ticket>> watchMyTickets();

  Stream<Ticket> watchTicket(String bookingId);

  /// Marks the paid booking cancelled, records [refund] on it and frees the
  /// seat, all at once. Fails if the booking is no longer paid.
  Future<void> cancelBooking(Ticket ticket, RefundQuote refund);

  /// Deletes the booking document for good.
  Future<void> deleteBooking(String bookingId);

  /// Every trip between the same two stations as [trip], whether it has
  /// left or not.
  Future<List<TripSummary>> findTrips(TripSummary trip);

  /// Moves the paid booking onto [DateChangeQuote.newTrip]: takes a free
  /// seat there, frees the old seat and records the change, all at once.
  /// Returns the updated ticket.
  Future<Ticket> changeTrip(Ticket ticket, DateChangeQuote quote);
}
