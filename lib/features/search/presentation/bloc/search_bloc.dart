import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/data/models/bus_operator.dart';
import 'package:bookme_summative_project/features/search/data/recent_routes_store.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/entities/city.dart';
import 'package:bookme_summative_project/features/search/domain/entities/search_query.dart';
import 'package:bookme_summative_project/features/search/domain/entities/trip_filter.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/search_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

/// Drives Home search, Results and Filters.
///
/// One Firestore query loads every trip on the route for the five days of
/// the date strip; changing the day or a filter is then done on the device.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required this._repository,
    this._recentRoutes,
    City? defaultOrigin,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(
         _initialState(
           defaultOrigin ?? Cities.kigali,
           (clock ?? DateTime.now)(),
         ),
       ) {
    on<SearchStarted>(_onStarted);
    on<SearchOriginChanged>(_onOriginChanged);
    on<SearchDestinationChanged>(_onDestinationChanged);
    on<SearchSwapped>(_onSwapped);
    on<SearchDateChanged>(_onDateChanged);
    on<SearchReturnDateChanged>(_onReturnDateChanged);
    on<SearchPassengersChanged>(_onPassengersChanged);
    on<SearchRecentSelected>(_onRecentSelected);
    on<SearchSubmitted>(_onSubmitted);
    on<SearchDaySelected>(_onDaySelected);
    on<SearchFilterChanged>(_onFilterChanged);
    on<SearchRefreshed>(_onRefreshed);
    on<_RecentRoutesSaved>(
      (event, emit) => emit(state.copyWith(recentRoutes: event.routes)),
    );
  }

  final SearchRepository _repository;
  final RecentRoutesStore? _recentRoutes;
  final DateTime Function() _now;

  /// Bumped on each load, so a slow older load can't overwrite a newer one.
  int _loadToken = 0;

  static SearchState _initialState(City origin, DateTime now) {
    final today = SearchQuery.dayOf(now);
    final destination = origin == Cities.kampala
        ? Cities.kigali
        : Cities.kampala;
    return SearchState(
      query: SearchQuery(origin: origin, destination: destination, date: today),
      windowStart: today,
      selectedDay: today,
      asOf: now,
    );
  }

  Future<void> _onStarted(
    SearchStarted event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(recentRoutes: _recentRoutes?.load()));
    try {
      emit(state.copyWith(operators: await _repository.operators()));
    } on SearchFailure {
      // Only the "N verified operators" caption uses this; search still works.
    }
  }

  void _onOriginChanged(SearchOriginChanged event, Emitter<SearchState> emit) {
    final q = state.query;
    // Picking the current destination as origin swaps the two.
    final destination = event.city == q.destination ? q.origin : q.destination;
    _setQuery(emit, q.copyWith(origin: event.city, destination: destination));
  }

  void _onDestinationChanged(
    SearchDestinationChanged event,
    Emitter<SearchState> emit,
  ) {
    final q = state.query;
    final origin = event.city == q.origin ? q.destination : q.origin;
    _setQuery(emit, q.copyWith(origin: origin, destination: event.city));
  }

  void _onSwapped(SearchSwapped event, Emitter<SearchState> emit) {
    final q = state.query;
    _setQuery(emit, q.copyWith(origin: q.destination, destination: q.origin));
  }

  void _onDateChanged(SearchDateChanged event, Emitter<SearchState> emit) {
    final today = SearchQuery.dayOf(_now());
    var date = SearchQuery.dayOf(event.date);
    if (date.isBefore(today)) date = today;
    final back = state.query.returnDate;
    final clearReturn = back != null && back.isBefore(date);
    _setQuery(
      emit,
      state.query.copyWith(date: date, clearReturnDate: clearReturn),
    );
  }

  void _onReturnDateChanged(
    SearchReturnDateChanged event,
    Emitter<SearchState> emit,
  ) {
    final date = event.date;
    _setQuery(
      emit,
      date == null
          ? state.query.copyWith(clearReturnDate: true)
          : state.query.copyWith(returnDate: SearchQuery.dayOf(date)),
    );
  }

  void _onPassengersChanged(
    SearchPassengersChanged event,
    Emitter<SearchState> emit,
  ) {
    final adults = event.adults.clamp(1, SearchQuery.maxPassengers);
    final children = event.children.clamp(
      0,
      SearchQuery.maxPassengers - adults,
    );
    _setQuery(emit, state.query.copyWith(adults: adults, children: children));
  }

  void _onRecentSelected(
    SearchRecentSelected event,
    Emitter<SearchState> emit,
  ) {
    _setQuery(
      emit,
      state.query.copyWith(
        origin: event.route.origin,
        destination: event.route.destination,
      ),
    );
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final query = state.query;
    final problem = query.problem;
    if (problem != null) {
      emit(state.copyWith(formError: problem));
      return;
    }
    emit(
      state.copyWith(
        clearFormError: true,
        filter: TripFilter.none,
        searchCount: state.searchCount + 1,
      ),
    );
    _remember(query);
    await _load(emit, day: query.date);
  }

  Future<void> _onDaySelected(
    SearchDaySelected event,
    Emitter<SearchState> emit,
  ) async {
    final day = SearchQuery.dayOf(event.day);
    final inWindow = state.days.contains(day);
    emit(state.copyWith(query: state.query.copyWith(date: day)));
    if (inWindow && state.status == ResultsStatus.success) {
      // Already loaded: just switch. The price filter is reset because the
      // new day's prices may sit outside it.
      emit(
        state.copyWith(
          selectedDay: day,
          filter: state.filter.copyWith(clearPrice: true),
        ),
      );
      return;
    }
    await _load(emit, day: day);
  }

  void _onFilterChanged(SearchFilterChanged event, Emitter<SearchState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  Future<void> _onRefreshed(SearchRefreshed event, Emitter<SearchState> emit) =>
      _load(emit, day: state.selectedDay);

  void _setQuery(Emitter<SearchState> emit, SearchQuery query) {
    emit(state.copyWith(query: query, clearFormError: true));
  }

  Future<void> _load(Emitter<SearchState> emit, {required DateTime day}) async {
    final token = ++_loadToken;
    final now = _now();
    final today = SearchQuery.dayOf(now);
    // The strip starts the day before the chosen date (never in the past).
    var start = DateTime(day.year, day.month, day.day - 1);
    if (start.isBefore(today)) start = today;
    final end = DateTime(
      start.year,
      start.month,
      start.day + SearchState.windowDays,
    );

    emit(
      state.copyWith(
        status: ResultsStatus.loading,
        windowStart: start,
        selectedDay: day,
        asOf: now,
        clearError: true,
      ),
    );

    try {
      final trips = await _repository.searchTrips(
        origin: state.query.origin.name,
        destination: state.query.destination.name,
        from: start,
        to: end,
      );
      if (token != _loadToken) return;
      emit(state.copyWith(status: ResultsStatus.success, windowTrips: trips));
    } on SearchFailure catch (e) {
      if (token != _loadToken) return;
      emit(
        state.copyWith(
          status: ResultsStatus.failure,
          windowTrips: const [],
          errorMessage: e.message,
        ),
      );
    }
  }

  void _remember(SearchQuery query) {
    final store = _recentRoutes;
    if (store == null) return;
    // Fire and forget: failing to save history must not block a search.
    store
        .remember(RecentRoute(query.origin, query.destination))
        .then((routes) {
          if (!isClosed) add(_RecentRoutesSaved(routes));
        })
        .catchError((Object _) {});
  }
}

/// Internal: refreshes "Book again" after a search is saved.
final class _RecentRoutesSaved extends SearchEvent {
  const _RecentRoutesSaved(this.routes);

  final List<RecentRoute> routes;
}
