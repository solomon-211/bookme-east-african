import 'package:bookme_summative_project/features/booking/data/datasources/firebase_error_mapper.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';

class TicketsRepositoryImpl implements TicketsRepository {
  TicketsRepositoryImpl(this._source);

  final TicketsDataSource _source;

  @override
  Stream<List<Ticket>> watchMyTickets() => _source.watchMyTickets().handleError(
    (Object e) => throw mapFirebaseError(
      e,
      fallback: 'We couldn\'t load your trips. Please try again.',
    ),
  );

  @override
  Stream<Ticket> watchTicket(String bookingId) => _source
      .watchTicket(bookingId)
      .handleError(
        (Object e) => throw mapFirebaseError(
          e,
          fallback: 'We couldn\'t load this ticket. Please try again.',
        ),
      );
}
