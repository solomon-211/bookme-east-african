import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';

import '../../../helpers/test_ticket.dart';

void main() {
  // Two days before the 4 Dec 2026 21:00 departure of testTicket.
  final now = DateTime(2026, 12, 2, 21);

  late InMemoryTicketsDataSource source;
  late TicketCacheDataSource cache;
  late TicketsRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = TicketCacheDataSource(await SharedPreferences.getInstance());
    source = InMemoryTicketsDataSource(initial: [testTicket()]);
    repository = TicketsRepositoryImpl(
      source: source,
      cache: cache,
      currentUserId: () => 'demo-user',
      clock: () => now,
    );
  });

  tearDown(() => source.dispose());

  test('cancelling records the refund and frees the seat', () async {
    final refund = await repository.cancelBooking(testTicket());

    expect(refund.reason, RefundReason.voluntary);
    expect(refund.refund, 18000); // Fare back, 500 service fee kept.
    expect(source.refunds['booking-1'], refund);
    expect(source.freedSeats, {'trip-1/4C'});

    final live = await repository.watchTicket('booking-1').first;
    expect(live.isCancelled, isTrue);
  });

  test('the ticket saved on the phone is marked cancelled too', () async {
    await cache.save('demo-user', [testTicket()]);

    await repository.cancelBooking(testTicket());

    expect(
      cache.load('demo-user').single.booking.status,
      BookingStatus.cancelled,
    );
  });

  test('a booking cannot be cancelled twice', () async {
    await repository.cancelBooking(testTicket());

    await expectLater(
      repository.cancelBooking(testTicket()),
      throwsA(isA<BookingFailure>()),
    );
    expect(source.refunds, hasLength(1));
  });

  test('a booking cannot be cancelled after the bus has left', () async {
    final afterDeparture = TicketsRepositoryImpl(
      source: source,
      cache: cache,
      currentUserId: () => 'demo-user',
      clock: () => DateTime(2026, 12, 4, 21, 5),
    );

    await expectLater(
      afterDeparture.cancelBooking(testTicket()),
      throwsA(isA<BookingFailure>()),
    );
    expect(source.refunds, isEmpty);
    expect(source.freedSeats, isEmpty);
  });
}
