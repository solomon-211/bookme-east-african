import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

import '../../../helpers/test_ticket.dart';

void main() {
  // testTicket departs 4 Dec 2026 at 21:00 and arrives 5 Dec at 06:30.
  final beforeDeparture = DateTime(2026, 12, 2, 21);
  final afterArrival = DateTime(2026, 12, 5, 12);

  late InMemoryTicketsDataSource source;
  late TicketCacheDataSource cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = TicketCacheDataSource(await SharedPreferences.getInstance());
  });

  tearDown(() => source.dispose());

  Future<TicketsRepositoryImpl> repositoryWith(
    Ticket ticket, {
    required DateTime now,
  }) async {
    source = InMemoryTicketsDataSource(initial: [ticket]);
    await cache.save('demo-user', [ticket]);
    return TicketsRepositoryImpl(
      source: source,
      cache: cache,
      currentUserId: () => 'demo-user',
      clock: () => now,
    );
  }

  test('a cancelled trip is deleted from the account and the phone', () async {
    final cancelled = testTicket(status: BookingStatus.cancelled);
    final repository = await repositoryWith(cancelled, now: beforeDeparture);

    await repository.removeFromHistory(cancelled);

    expect(await repository.watchMyTickets().first, isEmpty);
    expect(cache.load('demo-user'), isEmpty);
  });

  test('a finished trip can be removed', () async {
    final repository = await repositoryWith(testTicket(), now: afterArrival);

    await repository.removeFromHistory(testTicket());

    expect(await repository.watchMyTickets().first, isEmpty);
  });

  test('an upcoming trip is kept and must be cancelled first', () async {
    final repository = await repositoryWith(testTicket(), now: beforeDeparture);

    await expectLater(
      repository.removeFromHistory(testTicket()),
      throwsA(
        isA<BookingFailure>().having(
          (f) => f.message,
          'message',
          contains('Cancel the booking first'),
        ),
      ),
    );
    expect(await repository.watchMyTickets().first, [testTicket()]);
    expect(cache.load('demo-user'), [testTicket()]);
  });
}
