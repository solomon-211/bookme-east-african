import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';

/// The signed-in traveller's tickets. Implemented in the data layer with
/// Firestore (`bookings` joined with `trips`) plus an on-device cache.
abstract class TicketsRepository {
  /// Live list of the traveller's paid and cancelled bookings, newest
  /// departure first. Emits again whenever one of the bookings changes.
  /// Every list received is also saved to the on-device cache.
  Stream<List<Ticket>> watchMyTickets();

  /// Live updates for one ticket, used by the Digital Ticket screen.
  Stream<Ticket> watchTicket(String bookingId);

  /// The tickets saved on this device the last time [watchMyTickets]
  /// succeeded. Works with no connection.
  List<Ticket> cachedTickets();

  /// When the cached tickets were last refreshed, or `null` if never.
  DateTime? lastSyncedAt();

  /// Adds or refreshes one ticket in the on-device cache, so a ticket opened
  /// straight after payment works offline before My Trips is ever opened.
  Future<void> saveForOffline(Ticket ticket);

  /// Cancels [ticket], frees its seat and returns the refund that was
  /// recorded, worked out with [refundQuote] at the moment of cancelling.
  /// [delay] is how late the operator says the departure is running.
  ///
  /// Throws a `BookingFailure` when the booking can no longer be cancelled.
  Future<RefundQuote> cancelBooking(
    Ticket ticket, {
    Duration delay = Duration.zero,
  });
}
