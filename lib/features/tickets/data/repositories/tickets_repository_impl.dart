import 'package:bookme_summative_project/features/booking/data/datasources/firebase_error_mapper.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';

class TicketsRepositoryImpl implements TicketsRepository {
  TicketsRepositoryImpl({
    required this._source,
    required this._cache,
    required this._currentUserId,
  });

  final TicketsDataSource _source;
  final TicketCacheDataSource _cache;
  final String? Function() _currentUserId;

  @override
  Stream<List<Ticket>> watchMyTickets() => _source
      .watchMyTickets()
      .asyncMap((tickets) async {
        await _saveToCache(tickets);
        return tickets;
      })
      .handleError(
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

  @override
  List<Ticket> cachedTickets() {
    final uid = _currentUserId();
    return uid == null ? const [] : _cache.load(uid);
  }

  @override
  DateTime? lastSyncedAt() {
    final uid = _currentUserId();
    return uid == null ? null : _cache.lastSyncedAt(uid);
  }

  /// A full disk must never stop the live list from showing, so cache
  /// failures are ignored; the previous cache simply stays in place.
  Future<void> _saveToCache(List<Ticket> tickets) async {
    final uid = _currentUserId();
    if (uid == null) return;
    try {
      await _cache.save(uid, tickets);
    } on Object {
      // Keep the older cache.
    }
  }
}
