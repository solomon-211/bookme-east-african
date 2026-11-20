import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/change_date_cubit.dart';

import '../../../helpers/test_ticket.dart';
import '../../../helpers/test_trip.dart';

void main() {
  // Two days before testTicket's 4 Dec 2026 21:00 departure.
  final now = DateTime(2026, 12, 2, 21);

  final cheaper = otherDeparture(
    'trip-cheaper',
    departure: DateTime(2026, 12, 5, 7),
    baseFare: 15000,
  );
  final dearer = otherDeparture(
    'trip-dearer',
    departure: DateTime(2026, 12, 7, 21),
    baseFare: 20000,
  );

  late InMemoryTicketsDataSource source;

  Future<ChangeDateCubit> cubitWith({
    Map<String, List<String>> freeSeats = const {
      'trip-cheaper': ['2B'],
      'trip-dearer': ['1A'],
    },
  }) async {
    SharedPreferences.setMockInitialValues({});
    source = InMemoryTicketsDataSource(
      initial: [testTicket()],
      trips: [testTrip, dearer, cheaper],
      freeSeats: freeSeats,
    );
    final repository = TicketsRepositoryImpl(
      source: source,
      cache: TicketCacheDataSource(await SharedPreferences.getInstance()),
      currentUserId: () => 'demo-user',
      clock: () => now,
    );
    return ChangeDateCubit(
      repository: repository,
      ticket: testTicket(),
      clock: () => now,
    );
  }

  tearDown(() => source.dispose());

  test('loads the other departures, soonest first', () async {
    final cubit = await cubitWith();

    await cubit.load();

    expect(cubit.state.status, ChangeDateStatus.ready);
    expect(cubit.state.trips, [cheaper, dearer]);
    expect(cubit.canPick(cheaper), isTrue);
    expect(cubit.canPick(dearer), isFalse);
    await cubit.close();
  });

  test('a dearer departure cannot be selected', () async {
    final cubit = await cubitWith();
    await cubit.load();

    cubit.select(dearer);

    expect(cubit.state.selected, isNull);
    await cubit.close();
  });

  test('confirming moves the booking to the picked departure', () async {
    final cubit = await cubitWith();
    await cubit.load();

    cubit.select(cheaper);
    await cubit.confirm();

    expect(cubit.state.status, ChangeDateStatus.changed);
    expect(cubit.state.changed?.trip, cheaper);
    expect(cubit.state.changed?.booking.seatNumber, '2B');
    expect(source.changes.single.refund, 3000);
    await cubit.close();
  });

  test('a full departure explains why and keeps the list', () async {
    final cubit = await cubitWith(freeSeats: const {});
    await cubit.load();

    cubit.select(cheaper);
    await cubit.confirm();

    expect(cubit.state.status, ChangeDateStatus.ready);
    expect(cubit.state.trips, hasLength(2));
    expect(cubit.state.selected, isNull);
    expect(cubit.state.message, isNotNull);
    expect(source.changes, isEmpty);
    await cubit.close();
  });
}
