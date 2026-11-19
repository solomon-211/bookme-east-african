import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/date_change.dart';

import '../../../helpers/test_ticket.dart';
import '../../../helpers/test_trip.dart';

/// [testTrip] (18,500 RWF in total) on another day and at another price.
TripSummary otherDeparture(
  String id, {
  required DateTime departure,
  int baseFare = 18000,
  String toStation = 'Namirembe',
  String toCode = 'KLA',
}) => TripSummary(
  tripId: id,
  operatorName: testTrip.operatorName,
  fromCode: testTrip.fromCode,
  fromStation: testTrip.fromStation,
  toCode: toCode,
  toStation: toStation,
  departure: departure,
  arrival: departure.add(const Duration(hours: 9, minutes: 30)),
  durationLabel: testTrip.durationLabel,
  baseFare: baseFare,
  serviceFee: testTrip.serviceFee,
);

void main() {
  // Two days before testTicket's 4 Dec 2026 21:00 departure.
  final now = DateTime(2026, 12, 2, 21);

  final samePrice = otherDeparture(
    'trip-same',
    departure: DateTime(2026, 12, 6, 21),
  );
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
  final alreadyLeft = otherDeparture(
    'trip-left',
    departure: DateTime(2026, 12, 2, 8),
  );

  group('dateChangeQuote', () {
    test('a cheaper departure refunds the difference', () {
      final quote = dateChangeQuote(testTicket(), cheaper, now)!;

      expect(quote.newTotal, 15500);
      expect(quote.difference, -3000);
      expect(quote.refund, 3000);
      expect(quote.needsTopUp, isFalse);
    });

    test('a dearer departure needs a top-up', () {
      final quote = dateChangeQuote(testTicket(), dearer, now)!;

      expect(quote.difference, 2000);
      expect(quote.needsTopUp, isTrue);
      expect(quote.refund, 0);
    });

    test('no quote for the same trip, another route or a past departure', () {
      final elsewhere = otherDeparture(
        'trip-nbo',
        departure: DateTime(2026, 12, 6, 21),
        toStation: 'Nairobi',
        toCode: 'NBO',
      );

      expect(dateChangeQuote(testTicket(), testTrip, now), isNull);
      expect(dateChangeQuote(testTicket(), elsewhere, now), isNull);
      expect(dateChangeQuote(testTicket(), alreadyLeft, now), isNull);
    });
  });

  group('changeTrip', () {
    late InMemoryTicketsDataSource source;
    late TicketCacheDataSource cache;
    late TicketsRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      cache = TicketCacheDataSource(await SharedPreferences.getInstance());
      source = InMemoryTicketsDataSource(
        initial: [testTicket()],
        trips: [testTrip, dearer, samePrice, alreadyLeft, cheaper],
        freeSeats: {
          'trip-same': ['7A'],
          'trip-cheaper': ['2B'],
          'trip-dearer': ['1A'],
        },
      );
      repository = TicketsRepositoryImpl(
        source: source,
        cache: cache,
        currentUserId: () => 'demo-user',
        clock: () => now,
      );
    });

    tearDown(() => source.dispose());

    test('lists other departures on the route, soonest first', () async {
      final trips = await repository.alternativeTrips(testTicket());

      expect(trips.map((t) => t.tripId), [
        'trip-cheaper',
        'trip-same',
        'trip-dearer',
      ]);
    });

    test('moving to a cheaper departure takes a new seat', () async {
      final changed = await repository.changeTrip(testTicket(), cheaper);

      expect(changed.trip, cheaper);
      expect(changed.booking.seatNumber, '2B');
      expect(changed.booking.totalAmount, 15500);
      expect(changed.booking.reference, 'BME-7K2Q-4C');
      expect(source.freedSeats, {'trip-1/4C'});
      expect(source.changes.single.refund, 3000);
      expect(await repository.watchTicket('booking-1').first, changed);
      expect(cache.load('demo-user'), [changed]);
    });

    test('moving to a same-price departure refunds nothing', () async {
      await repository.changeTrip(testTicket(), samePrice);

      expect(source.changes.single.refund, 0);
    });

    test('a dearer departure is refused until top-ups exist', () async {
      await expectLater(
        repository.changeTrip(testTicket(), dearer),
        throwsA(
          isA<BookingFailure>().having(
            (f) => f.message,
            'message',
            contains('2,000 RWF more'),
          ),
        ),
      );
      expect(source.changes, isEmpty);
      expect(source.freedSeats, isEmpty);
    });

    test('a full departure is refused and nothing changes', () async {
      final full = otherDeparture(
        'trip-full',
        departure: DateTime(2026, 12, 8, 21),
      );

      await expectLater(
        repository.changeTrip(testTicket(), full),
        throwsA(isA<BookingFailure>()),
      );
      expect((await repository.watchTicket('booking-1').first).trip, testTrip);
    });
  });
}
