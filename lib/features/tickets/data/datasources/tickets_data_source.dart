import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
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
}
