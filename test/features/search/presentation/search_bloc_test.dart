import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/search/data/recent_routes_store.dart';
import 'package:bookme_summative_project/features/search/data/repositories/in_memory_search_repositories.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/entities/city.dart';
import 'package:bookme_summative_project/features/search/domain/entities/trip_filter.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/search_repository.dart';
import 'package:bookme_summative_project/features/search/presentation/bloc/search_bloc.dart';

void main() {
  // Thursday 1 Oct 2026, 08:00.
  final now = DateTime(2026, 10, 1, 8);
  late InMemorySearchRepository repository;

  setUp(() {
    repository = InMemorySearchRepository.seeded(now, days: 10);
  });

  SearchBloc build({RecentRoutesStore? recent}) => SearchBloc(
    repository: repository,
    recentRoutes: recent,
    clock: () => now,
  );

  test('starts on Kigali → Kampala today with one adult', () {
    final bloc = build();
    expect(bloc.state.query.origin, Cities.kigali);
    expect(bloc.state.query.destination, Cities.kampala);
    expect(bloc.state.query.date, DateTime(2026, 10, 1));
    expect(bloc.state.query.adults, 1);
    expect(bloc.state.status, ResultsStatus.idle);
  });

  blocTest<SearchBloc, SearchState>(
    'SearchStarted loads operators for the home caption',
    build: build,
    act: (b) => b.add(const SearchStarted()),
    wait: Duration.zero,
    verify: (b) => expect(b.state.verifiedOperatorCount, 5),
  );

  blocTest<SearchBloc, SearchState>(
    'swap trades From and To',
    build: build,
    act: (b) => b.add(const SearchSwapped()),
    verify: (b) {
      expect(b.state.query.origin, Cities.kampala);
      expect(b.state.query.destination, Cities.kigali);
    },
  );

  blocTest<SearchBloc, SearchState>(
    'choosing the destination as origin swaps instead of duplicating',
    build: build,
    act: (b) => b.add(const SearchOriginChanged(Cities.kampala)),
    verify: (b) {
      expect(b.state.query.origin, Cities.kampala);
      expect(b.state.query.destination, Cities.kigali);
    },
  );

  blocTest<SearchBloc, SearchState>(
    'a past date snaps to today and drops an earlier return date',
    build: build,
    act: (b) => b
      ..add(SearchReturnDateChanged(DateTime(2026, 10, 3)))
      ..add(SearchDateChanged(DateTime(2026, 9, 20)))
      ..add(SearchDateChanged(DateTime(2026, 10, 5))),
    verify: (b) {
      expect(b.state.query.date, DateTime(2026, 10, 5));
      expect(b.state.query.returnDate, isNull);
    },
  );

  blocTest<SearchBloc, SearchState>(
    'passenger counts stay within 1–9 seats',
    build: build,
    act: (b) => b
      ..add(const SearchPassengersChanged(adults: 0, children: 0))
      ..add(const SearchPassengersChanged(adults: 6, children: 7)),
    verify: (b) {
      expect(b.state.query.adults, 6);
      expect(b.state.query.children, 3);
    },
  );

  blocTest<SearchBloc, SearchState>(
    'submit loads five days of trips in one query and opens results',
    build: build,
    act: (b) => b.add(const SearchSubmitted()),
    wait: Duration.zero,
    verify: (b) {
      final s = b.state;
      expect(s.status, ResultsStatus.success);
      expect(s.searchCount, 1);
      expect(repository.searchCalls, 1);
      expect(s.days.first, DateTime(2026, 10, 1)); // never before today
      expect(s.days, hasLength(5));
      // 5 Kigali → Kampala departures a day; 07:00 already left at 08:00.
      expect(s.dayTrips.map((t) => t.operatorName).toSet(), {
        'Trinity Express',
        'Jaguar',
        'RITCO',
      });
      expect(s.visibleTrips.every((t) => t.departure.isAfter(now)), isTrue);
      expect(s.operatorOptions, hasLength(4));
    },
  );

  blocTest<SearchBloc, SearchState>(
    'same From and To is refused with a message, no query',
    build: build,
    seed: () => build().state.copyWith(
      query: build().state.query.copyWith(destination: Cities.kigali),
    ),
    act: (b) => b.add(const SearchSubmitted()),
    verify: (b) {
      expect(b.state.formError, isNotNull);
      expect(b.state.searchCount, 0);
      expect(repository.searchCalls, 0);
    },
  );

  blocTest<SearchBloc, SearchState>(
    'picking another day inside the strip needs no new query',
    build: build,
    act: (b) async {
      b.add(const SearchSubmitted());
      await Future<void>.delayed(Duration.zero);
      b.add(SearchDaySelected(DateTime(2026, 10, 3)));
    },
    wait: Duration.zero,
    verify: (b) {
      expect(repository.searchCalls, 1);
      expect(b.state.selectedDay, DateTime(2026, 10, 3));
      expect(b.state.dayTrips.every((t) => t.departure.day == 3), isTrue);
      // Volcano 07:00 is always full in the seed; full buses are listed
      // after every bus that still has seats.
      final trips = b.state.visibleTrips;
      final firstFull = trips.indexWhere((t) => t.isFull);
      expect(firstFull, greaterThan(0));
      expect(trips.skip(firstFull).every((t) => t.isFull), isTrue);
      expect(
        trips.skip(firstFull).map((t) => t.operatorName),
        contains('Volcano Express'),
      );
    },
  );

  blocTest<SearchBloc, SearchState>(
    'a day outside the strip loads a new window',
    build: build,
    act: (b) async {
      b.add(const SearchSubmitted());
      await Future<void>.delayed(Duration.zero);
      b.add(SearchDaySelected(DateTime(2026, 10, 8)));
    },
    wait: Duration.zero,
    verify: (b) {
      expect(repository.searchCalls, 2);
      expect(b.state.days.first, DateTime(2026, 10, 7));
    },
  );

  blocTest<SearchBloc, SearchState>(
    'filters narrow the visible list without a query',
    build: build,
    act: (b) async {
      b.add(const SearchSubmitted());
      await Future<void>.delayed(Duration.zero);
      b.add(
        const SearchFilterChanged(
          TripFilter(window: DepartureWindow.night, amenities: {Amenity.wifi}),
        ),
      );
    },
    wait: Duration.zero,
    verify: (b) {
      expect(repository.searchCalls, 1);
      expect(b.state.visibleTrips.map((t) => t.operatorName).toSet(), {
        'Trinity Express',
      });
    },
  );

  blocTest<SearchBloc, SearchState>(
    'a failed load shows the message and can be retried',
    build: () {
      repository.failure = const SearchFailure('offline');
      return build();
    },
    act: (b) async {
      b.add(const SearchSubmitted());
      await Future<void>.delayed(Duration.zero);
      expect(b.state.status, ResultsStatus.failure);
      expect(b.state.errorMessage, 'offline');
      repository.failure = null;
      b.add(const SearchRefreshed());
    },
    wait: Duration.zero,
    verify: (b) {
      expect(b.state.status, ResultsStatus.success);
      expect(b.state.errorMessage, isNull);
    },
  );

  test('remembers searched routes for "Book again"', () async {
    SharedPreferences.setMockInitialValues({});
    final store = RecentRoutesStore(await SharedPreferences.getInstance());
    final bloc = build(recent: store);
    bloc
      ..add(const SearchSubmitted())
      ..add(const SearchSwapped())
      ..add(const SearchSubmitted());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.recentRoutes, const [
      RecentRoute(Cities.kampala, Cities.kigali),
      RecentRoute(Cities.kigali, Cities.kampala),
    ]);
    await bloc.close();
  });
}
