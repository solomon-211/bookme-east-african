import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

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
}
