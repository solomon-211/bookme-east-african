import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

/// Storage for the traveller's tickets.
///
/// Implemented with Firestore by `TicketsFirestoreDataSource`.
abstract interface class TicketsDataSource {
  Stream<List<Ticket>> watchMyTickets();

  Stream<Ticket> watchTicket(String bookingId);
}
