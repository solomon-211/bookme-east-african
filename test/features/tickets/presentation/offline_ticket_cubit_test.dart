import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/offline_ticket_cubit.dart';

import '../../../helpers/test_ticket.dart';

void main() {
  late TicketCacheDataSource cache;
  late TicketsRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = TicketCacheDataSource(await SharedPreferences.getInstance());
    repository = TicketsRepositoryImpl(
      source: InMemoryTicketsDataSource(),
      cache: cache,
      currentUserId: () => 'demo-user',
    );
  });

  test('shows the copy saved on the phone', () async {
    await cache.save('demo-user', [testTicket(seat: '9A')]);
    final cubit = OfflineTicketCubit(
      repository: repository,
      bookingId: 'booking-1',
      fallback: testTicket(),
    );

    await cubit.load();

    expect(cubit.state.ticket?.booking.seatNumber, '9A');
    expect(cubit.state.savedAt, isNotNull);
    await cubit.close();
  });

  test('uses and saves the ticket it was given when none is saved', () async {
    final cubit = OfflineTicketCubit(
      repository: repository,
      bookingId: 'booking-1',
      fallback: testTicket(),
    );

    await cubit.load();

    expect(cubit.state.ticket, testTicket());
    expect(cache.load('demo-user'), [testTicket()]);
    await cubit.close();
  });

  test('reports a missing ticket when nothing is available', () async {
    final cubit = OfflineTicketCubit(
      repository: repository,
      bookingId: 'booking-1',
    );

    await cubit.load();

    expect(cubit.state.isMissing, isTrue);
    await cubit.close();
  });
}
