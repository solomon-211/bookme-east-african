import 'package:equatable/equatable.dart';

import 'package:bookme_summative_project/features/search/domain/entities/city.dart';

/// What the traveller typed on "Where to next?".
class SearchQuery extends Equatable {
  const SearchQuery({
    required this.origin,
    required this.destination,
    required this.date,
    this.returnDate,
    this.adults = 1,
    this.children = 0,
  });

  static const int maxPassengers = 9;

  final City origin;
  final City destination;

  /// Departure day. Only the calendar date matters.
  final DateTime date;
  final DateTime? returnDate;
  final int adults;
  final int children;

  int get passengers => adults + children;

  /// `null` when the query can be searched, otherwise what to fix.
  String? get problem {
    if (origin == destination) {
      return 'Pick a destination different from where you leave.';
    }
    if (adults < 1) return 'At least one adult must travel.';
    if (passengers > maxPassengers) {
      return 'You can book up to $maxPassengers seats at once.';
    }
    final back = returnDate;
    if (back != null && dayOf(back).isBefore(dayOf(date))) {
      return 'The return date must be on or after the departure date.';
    }
    return null;
  }

  bool get isValid => problem == null;

  /// `1 adult`, `2 adults · 1 child`.
  String get passengerLabel {
    final a = '$adults adult${adults == 1 ? '' : 's'}';
    if (children == 0) return a;
    return '$a · $children child${children == 1 ? '' : 'ren'}';
  }

  SearchQuery copyWith({
    City? origin,
    City? destination,
    DateTime? date,
    DateTime? returnDate,
    bool clearReturnDate = false,
    int? adults,
    int? children,
  }) => SearchQuery(
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    date: date ?? this.date,
    returnDate: clearReturnDate ? null : (returnDate ?? this.returnDate),
    adults: adults ?? this.adults,
    children: children ?? this.children,
  );

  /// Midnight at the start of [value]'s day.
  static DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  List<Object?> get props => [
    origin,
    destination,
    date,
    returnDate,
    adults,
    children,
  ];
}
