import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

/// The signed-in traveller's tickets. Implemented in the data layer with
/// Firestore (`bookings` joined with `trips`).
abstract class TicketsRepository {
  /// Live list of the traveller's paid and cancelled bookings, newest
  /// departure first. Emits again whenever a booking or its trip changes.
  Stream<List<Ticket>> watchMyTickets();

  /// Live updates for one ticket, used by the Digital Ticket screen.
  Stream<Ticket> watchTicket(String bookingId);
}
