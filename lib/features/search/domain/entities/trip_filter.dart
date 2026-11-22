import 'package:equatable/equatable.dart';

import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';

/// Departure-time buckets on "Find your bus".
enum DepartureWindow {
  any('Any time'),
  morning('Morning · 06–12'),
  afternoon('Afternoon · 12–18'),
  night('Night · 18–06');

  const DepartureWindow(this.label);

  final String label;

  /// Whether a bus leaving at [time] falls in this window.
  bool contains(DateTime time) {
    final h = time.hour;
    switch (this) {
      case DepartureWindow.any:
        return true;
      case DepartureWindow.morning:
        return h >= 6 && h < 12;
      case DepartureWindow.afternoon:
        return h >= 12 && h < 18;
      case DepartureWindow.night:
        // Wraps past midnight: 18:00 up to 05:59.
        return h >= 18 || h < 6;
    }
  }
}

/// Lowest and highest per-traveller total in a list of trips.
class PriceRange extends Equatable {
  const PriceRange(this.min, this.max);

  final int min;
  final int max;

  /// `null` for an empty list.
  static PriceRange? of(Iterable<BusTrip> trips) {
    int? low;
    int? high;
    for (final trip in trips) {
      final t = trip.total;
      if (low == null || t < low) low = t;
      if (high == null || t > high) high = t;
    }
    if (low == null || high == null) return null;
    return PriceRange(low, high);
  }

  @override
  List<Object?> get props => [min, max];
}

/// The filters a traveller set on the results.
///
/// Empty sets and null prices mean "no limit". Filtering happens on the
/// device, after the Firestore query for route + day, so changing a filter
/// costs no reads.
class TripFilter extends Equatable {
  const TripFilter({
    this.window = DepartureWindow.any,
    this.minPrice,
    this.maxPrice,
    this.operatorIds = const {},
    this.amenities = const {},
  });

  static const none = TripFilter();

  final DepartureWindow window;

  /// Bounds on [BusTrip.total] (taxes and fees included), inclusive.
  final int? minPrice;
  final int? maxPrice;

  /// Only these operators. Empty = every operator.
  final Set<String> operatorIds;

  /// The bus must have all of these.
  final Set<Amenity> amenities;

  bool get isActive => activeCount > 0;

  /// Number of filter groups in use, for the "Filters (2)" chip.
  int get activeCount =>
      (window == DepartureWindow.any ? 0 : 1) +
      (minPrice == null && maxPrice == null ? 0 : 1) +
      (operatorIds.isEmpty ? 0 : 1) +
      (amenities.isEmpty ? 0 : 1);

  bool matches(BusTrip trip) {
    if (!window.contains(trip.departure)) return false;
    final min = minPrice;
    if (min != null && trip.total < min) return false;
    final max = maxPrice;
    if (max != null && trip.total > max) return false;
    if (operatorIds.isNotEmpty && !operatorIds.contains(trip.operatorId)) {
      return false;
    }
    return amenities.every(trip.hasAmenity);
  }

  /// Trips that pass the filter, ready to show:
  /// * cancelled trips and buses that already left are dropped;
  /// * buses with seats come first, by departure time;
  /// * fully booked buses go last, so the waitlist option stays visible
  ///   without pushing bookable buses down.
  List<BusTrip> apply(Iterable<BusTrip> trips, {DateTime? now}) {
    final result = trips.where((trip) {
      if (trip.isCancelled) return false;
      if (now != null && !trip.departure.isAfter(now)) return false;
      return matches(trip);
    }).toList();
    result.sort((a, b) {
      if (a.isFull != b.isFull) return a.isFull ? 1 : -1;
      return a.departure.compareTo(b.departure);
    });
    return result;
  }

  TripFilter copyWith({
    DepartureWindow? window,
    int? minPrice,
    int? maxPrice,
    bool clearPrice = false,
    Set<String>? operatorIds,
    Set<Amenity>? amenities,
  }) => TripFilter(
    window: window ?? this.window,
    minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
    maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
    operatorIds: operatorIds ?? this.operatorIds,
    amenities: amenities ?? this.amenities,
  );

  /// Adds [amenity] if missing, removes it if present.
  TripFilter toggleAmenity(Amenity amenity) {
    final next = {...amenities};
    if (!next.remove(amenity)) next.add(amenity);
    return copyWith(amenities: next);
  }

  @override
  List<Object?> get props => [window, minPrice, maxPrice, operatorIds, amenities];
}
