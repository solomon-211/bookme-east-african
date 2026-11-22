part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Loads operators and recent routes for the home screen.
final class SearchStarted extends SearchEvent {
  const SearchStarted();
}

final class SearchOriginChanged extends SearchEvent {
  const SearchOriginChanged(this.city);

  final City city;

  @override
  List<Object?> get props => [city];
}

final class SearchDestinationChanged extends SearchEvent {
  const SearchDestinationChanged(this.city);

  final City city;

  @override
  List<Object?> get props => [city];
}

/// The ⇅ button: From and To trade places.
final class SearchSwapped extends SearchEvent {
  const SearchSwapped();
}

final class SearchDateChanged extends SearchEvent {
  const SearchDateChanged(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

/// `null` removes the return date.
final class SearchReturnDateChanged extends SearchEvent {
  const SearchReturnDateChanged(this.date);

  final DateTime? date;

  @override
  List<Object?> get props => [date];
}

final class SearchPassengersChanged extends SearchEvent {
  const SearchPassengersChanged({required this.adults, required this.children});

  final int adults;
  final int children;

  @override
  List<Object?> get props => [adults, children];
}

/// A "Book again" tile: fills From / To.
final class SearchRecentSelected extends SearchEvent {
  const SearchRecentSelected(this.route);

  final RecentRoute route;

  @override
  List<Object?> get props => [route];
}

/// "Search Buses".
final class SearchSubmitted extends SearchEvent {
  const SearchSubmitted();
}

/// A day in the date strip on the results.
final class SearchDaySelected extends SearchEvent {
  const SearchDaySelected(this.day);

  final DateTime day;

  @override
  List<Object?> get props => [day];
}

final class SearchFilterChanged extends SearchEvent {
  const SearchFilterChanged(this.filter);

  final TripFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// "Try again" after a failed load, or pull to refresh.
final class SearchRefreshed extends SearchEvent {
  const SearchRefreshed();
}
