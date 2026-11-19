import 'package:bookme_summative_project/features/booking/data/datasources/firebase_error_mapper.dart';
import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';

class TicketsRepositoryImpl implements TicketsRepository {
  TicketsRepositoryImpl({
    required this._source,
    required this._cache,
    required this._currentUserId,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final TicketsDataSource _source;
  final TicketCacheDataSource _cache;
  final String? Function() _currentUserId;
  final DateTime Function() _now;

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

  @override
  Future<void> saveForOffline(Ticket ticket) async {
    final uid = _currentUserId();
    if (uid == null) return;
    final others = _cache.load(uid).where((t) => t.id != ticket.id);
    await _cache.save(uid, [ticket, ...others]);
  }

  @override
  Future<RefundQuote> cancelBooking(
    Ticket ticket, {
    Duration delay = Duration.zero,
  }) async {
    final refund = refundQuote(ticket, _now(), delay: delay);
    if (refund == null) {
      throw const BookingFailure(
        'This booking can no longer be cancelled. The bus has left or it '
        'was already cancelled.',
      );
    }
    try {
      await _source.cancelBooking(ticket, refund);
    } on Object catch (e) {
      throw mapFirebaseError(
        e,
        fallback: 'We couldn\'t cancel this booking. Please try again.',
      );
    }
    // The saved copy must stop showing a valid boarding QR straight away,
    // even before the live list refreshes.
    try {
      await saveForOffline(
        Ticket(
          booking: ticket.booking.copyWith(status: BookingStatus.cancelled),
          trip: ticket.trip,
          tripStatus: ticket.tripStatus,
        ),
      );
    } on Object {
      // The live update replaces the cache on the next sync.
    }
    return refund;
  }

  @override
  Future<void> removeFromHistory(Ticket ticket) async {
    if (!ticket.isPast(_now())) {
      throw const BookingFailure(
        'Upcoming trips can\'t be removed. Cancel the booking first.',
      );
    }
    try {
      await _source.deleteBooking(ticket.id);
    } on Object catch (e) {
      throw mapFirebaseError(
        e,
        fallback: 'We couldn\'t remove this trip. Please try again.',
      );
    }
    final uid = _currentUserId();
    if (uid == null) return;
    try {
      final rest = _cache.load(uid).where((t) => t.id != ticket.id).toList();
      await _cache.save(uid, rest);
    } on Object {
      // The live list no longer has it, so the next sync drops it.
    }
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
