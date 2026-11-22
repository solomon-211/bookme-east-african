part of 'search_bloc.dart';

enum ResultsStatus { idle, loading, success, failure }

/// Option in the Operator filter.
class OperatorOption extends Equatable {
  const OperatorOption(this.id, this.name);

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class SearchState extends Equatable {
  const SearchState({
    required this.query,
    required this.windowStart,
    required this.selectedDay,
    required this.asOf,
    this.status = ResultsStatus.idle,
    this.windowTrips = const [],
    this.filter = TripFilter.none,
    this.operators = const [],
    this.recentRoutes = const [],
    this.errorMessage,
    this.formError,
    this.searchCount = 0,
  });

  /// Days shown in the strip on the results screen.
  static const int windowDays = 5;

  final SearchQuery query;
  final ResultsStatus status;

  /// Every trip on the route for the [windowDays] days of the strip. One
  /// query loads them all, so tapping another day costs no reads.
  final List<BusTrip> windowTrips;
  final DateTime windowStart;
  final DateTime selectedDay;
  final TripFilter filter;

  /// From the `operators` collection; counted on the home screen.
  final List<BusOperator> operators;
  final List<RecentRoute> recentRoutes;

  /// Why the results failed to load.
  final String? errorMessage;

  /// Why "Search Buses" was refused (e.g. same From and To).
  final String? formError;

  /// Goes up by one on every accepted search; the home screen opens the
  /// results when it changes.
  final int searchCount;

  /// When the results were loaded. Buses that left before this are hidden.
  final DateTime asOf;

  List<DateTime> get days => [
    for (var i = 0; i < windowDays; i++)
      DateTime(windowStart.year, windowStart.month, windowStart.day + i),
  ];

  /// The selected day's trips, before filters.
  List<BusTrip> get dayTrips => tripsOn(selectedDay);

  /// What the results list shows.
  List<BusTrip> get visibleTrips => filter.apply(dayTrips, now: asOf);

  /// Trips that would show on [day] with no filters.
  List<BusTrip> tripsOn(DateTime day) => windowTrips
      .where((t) => _sameDay(t.departure, day))
      .where((t) => !t.isCancelled && t.departure.isAfter(asOf))
      .toList();

  /// Cheapest bookable fare per day of the strip, `null` if none.
  int? lowestFareOn(DateTime day) {
    final bookable = tripsOn(day).where((t) => !t.isFull);
    return PriceRange.of(bookable)?.min;
  }

  /// Bounds for the price slider: the selected day's cheapest and dearest.
  PriceRange? get priceRange => PriceRange.of(dayTrips);

  /// Operators running this route in the window, by name.
  List<OperatorOption> get operatorOptions {
    final byId = <String, String>{
      for (final t in windowTrips) t.operatorId: t.operatorName,
    };
    final options = [for (final e in byId.entries) OperatorOption(e.key, e.value)];
    options.sort((a, b) => a.name.compareTo(b.name));
    return options;
  }

  int get verifiedOperatorCount => operators.where((o) => o.isVerified).length;

  String get currency =>
      dayTrips.isEmpty ? query.origin.currency : dayTrips.first.currency;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  SearchState copyWith({
    SearchQuery? query,
    ResultsStatus? status,
    List<BusTrip>? windowTrips,
    DateTime? windowStart,
    DateTime? selectedDay,
    TripFilter? filter,
    List<BusOperator>? operators,
    List<RecentRoute>? recentRoutes,
    String? errorMessage,
    bool clearError = false,
    String? formError,
    bool clearFormError = false,
    int? searchCount,
    DateTime? asOf,
  }) => SearchState(
    query: query ?? this.query,
    status: status ?? this.status,
    windowTrips: windowTrips ?? this.windowTrips,
    windowStart: windowStart ?? this.windowStart,
    selectedDay: selectedDay ?? this.selectedDay,
    filter: filter ?? this.filter,
    operators: operators ?? this.operators,
    recentRoutes: recentRoutes ?? this.recentRoutes,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    formError: clearFormError ? null : (formError ?? this.formError),
    searchCount: searchCount ?? this.searchCount,
    asOf: asOf ?? this.asOf,
  );

  @override
  List<Object?> get props => [
    query,
    status,
    windowTrips,
    windowStart,
    selectedDay,
    filter,
    operators,
    recentRoutes,
    errorMessage,
    formError,
    searchCount,
    asOf,
  ];
}
