import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/date_change.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/ticket_cubit.dart';

import '../../../helpers/test_ticket.dart';

/// A data source the test pushes tickets and errors into by hand.
class _ManualSource implements TicketsDataSource {
  final StreamController<Ticket> ticket = StreamController<Ticket>();

  @override
  Stream<Ticket> watchTicket(String bookingId) => ticket.stream;

  @override
  Stream<List<Ticket>> watchMyTickets() => const Stream.empty();

  @override
  Future<void> cancelBooking(Ticket ticket, RefundQuote refund) async {}

  @override
  Future<void> deleteBooking(String bookingId) async {}

  @override
  Future<List<TripSummary>> findTrips(TripSummary trip) async => const [];

  @override
  Future<Ticket> changeTrip(Ticket ticket, DateChangeQuote quote) =>
      throw UnimplementedError();
}

void main() {
  late _ManualSource source;
  late TicketCacheDataSource cache;
  late TicketsRepositoryImpl repository;
  late TicketCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = TicketCacheDataSource(await SharedPreferences.getInstance());
    source = _ManualSource();
    repository = TicketsRepositoryImpl(
      source: source,
      cache: cache,
      currentUserId: () => 'demo-user',
    );
    cubit = TicketCubit(repository: repository, bookingId: 'booking-1');
  });

  tearDown(() => cubit.close());

  test('shows the live ticket and saves it on the phone', () async {
    await cubit.load();
    expect(cubit.state.status, TicketStatus.loading);

    source.ticket.add(testTicket());
    await pumpEventQueue();

    expect(cubit.state.status, TicketStatus.loaded);
    expect(cubit.state.ticket, testTicket());
    expect(cache.load('demo-user'), [testTicket()]);
  });

  test('falls back to the saved copy when offline', () async {
    await cache.save('demo-user', [testTicket()]);

    await cubit.load();
    expect(cubit.state.ticket, testTicket());

    source.ticket.addError(Exception('unavailable'));
    await pumpEventQueue();

    expect(cubit.state.status, TicketStatus.loaded);
    expect(cubit.state.isOffline, isTrue);
    expect(cubit.state.ticket, testTicket());
  });

  test('fails when offline with nothing saved', () async {
    await cubit.load();
    source.ticket.addError(Exception('unavailable'));
    await pumpEventQueue();

    expect(cubit.state.status, TicketStatus.failure);
    expect(cubit.state.message, isNotNull);
  });

  test('save to phone keeps other saved tickets', () async {
    await cache.save('demo-user', [testTicket(id: 'booking-2')]);
    await cubit.load();
    source.ticket.add(testTicket());
    await pumpEventQueue();

    await cubit.saveToPhone();

    expect(cubit.state.savedAt, isNotNull);
    expect(cache.load('demo-user').map((t) => t.id), [
      'booking-1',
      'booking-2',
    ]);
  });
}
