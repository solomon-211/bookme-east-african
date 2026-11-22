import 'package:equatable/equatable.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';

/// Something on board the bus. [code] is what Firestore stores.
enum Amenity {
  wifi('wifi', 'Wi-Fi'),
  ac('ac', 'AC'),
  recliningSeats('reclining', 'Reclining seats'),
  usbCharging('usb', 'USB charging'),
  toilet('toilet', 'Toilet');

  const Amenity(this.code, this.label);

  final String code;
  final String label;

  static Amenity? fromCode(String code) {
    for (final amenity in values) {
      if (amenity.code == code) return amenity;
    }
    return null;
  }
}

/// One stop on the way, e.g. the border post.
class TripStop extends Equatable {
  const TripStop({required this.name, required this.time, this.note = ''});

  final String name;
  final DateTime time;

  /// e.g. `Scheduled stop · Passport / EAC ID check`.
  final String note;

  @override
  List<Object?> get props => [name, time, note];
}

class TripStatus {
  const TripStatus._();

  static const scheduled = 'scheduled';
  static const delayed = 'delayed';
  static const cancelled = 'cancelled';
}

/// A scheduled departure as Search shows it: `trips/{tripId}`.
///
/// Operator name, rating and verified flag are copied onto the trip so a
/// results list needs one query and no joins.
class BusTrip extends Equatable {
  const BusTrip({
    required this.id,
    required this.routeId,
    required this.operatorId,
    required this.operatorName,
    required this.origin,
    required this.fromCode,
    required this.fromStation,
    required this.destination,
    required this.toCode,
    required this.toStation,
    required this.departure,
    required this.arrival,
    required this.price,
    required this.currency,
    required this.seatsTotal,
    required this.seatsAvailable,
    this.serviceClass = 'Standard',
    this.operatorRating = 0,
    this.operatorVerified = false,
    this.taxes = 0,
    this.serviceFee = 0,
    this.status = TripStatus.scheduled,
    this.amenities = const {},
    this.stops = const [],
  });

  final String id;
  final String routeId;
  final String operatorId;
  final String operatorName;
  final String serviceClass;
  final double operatorRating;
  final bool operatorVerified;

  final String origin;
  final String fromCode;
  final String fromStation;
  final String destination;
  final String toCode;
  final String toStation;

  final DateTime departure;
  final DateTime arrival;

  /// Base fare per seat, whole units of [currency].
  final int price;
  final int taxes;
  final int serviceFee;
  final String currency;

  final int seatsTotal;
  final int seatsAvailable;
  final String status;
  final Set<Amenity> amenities;

  /// Stops between departure and arrival, in order.
  final List<TripStop> stops;

  /// What one traveller pays: fare + taxes + service fee, nothing hidden.
  int get total => price + taxes + serviceFee;

  Duration get duration => arrival.difference(departure);

  bool get isCancelled => status == TripStatus.cancelled;
  bool get isFull => seatsAvailable <= 0;

  /// Few enough seats left to warn about.
  bool get isAlmostFull => !isFull && seatsAvailable <= 15;

  /// Arrives on a later calendar day than it leaves.
  bool get isOvernight =>
      DateTime(arrival.year, arrival.month, arrival.day)
          .isAfter(DateTime(departure.year, departure.month, departure.day));

  bool isBookable(DateTime now) =>
      !isCancelled && !isFull && departure.isAfter(now);

  bool hasAmenity(Amenity amenity) => amenities.contains(amenity);

  /// The snapshot the Booking & Payment flow takes.
  TripSummary toSummary() => TripSummary(
    tripId: id,
    operatorName: operatorName,
    fromCode: fromCode,
    fromStation: fromStation,
    toCode: toCode,
    toStation: toStation,
    departure: departure,
    arrival: arrival,
    durationLabel: durationLabel(duration),
    baseFare: price,
    taxes: taxes,
    serviceFee: serviceFee,
    currency: currency,
  );

  BusTrip copyWith({int? seatsAvailable, String? status}) => BusTrip(
    id: id,
    routeId: routeId,
    operatorId: operatorId,
    operatorName: operatorName,
    serviceClass: serviceClass,
    operatorRating: operatorRating,
    operatorVerified: operatorVerified,
    origin: origin,
    fromCode: fromCode,
    fromStation: fromStation,
    destination: destination,
    toCode: toCode,
    toStation: toStation,
    departure: departure,
    arrival: arrival,
    price: price,
    taxes: taxes,
    serviceFee: serviceFee,
    currency: currency,
    seatsTotal: seatsTotal,
    seatsAvailable: seatsAvailable ?? this.seatsAvailable,
    status: status ?? this.status,
    amenities: amenities,
    stops: stops,
  );

  /// `Duration(hours: 9, minutes: 30)` → `9h 30m`.
  static String durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  @override
  List<Object?> get props => [
    id,
    routeId,
    operatorId,
    operatorName,
    serviceClass,
    operatorRating,
    operatorVerified,
    origin,
    fromCode,
    fromStation,
    destination,
    toCode,
    toStation,
    departure,
    arrival,
    price,
    taxes,
    serviceFee,
    currency,
    seatsTotal,
    seatsAvailable,
    status,
    amenities,
    stops,
  ];
}
