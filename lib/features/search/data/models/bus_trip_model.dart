import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/entities/city.dart';

/// Converts `trips/{tripId}` documents to and from [BusTrip].
///
/// Field names follow `lib/data/models/trip.dart` (origin, destination,
/// departureTime, arrivalTime, price, ...) and add `fromCode`,
/// `fromStation`, `toCode`, `toStation`, `taxes` and `serviceFee`, so
/// Tickets' `TripDocumentMapper` reads the same documents unchanged.
class BusTripModel {
  const BusTripModel._();

  /// Returns `null` when a required field is missing or the wrong type,
  /// so one bad document hides one result instead of failing the search.
  static BusTrip? fromMap(String id, Map<String, dynamic> map) {
    try {
      final origin = map['origin'] as String;
      final destination = map['destination'] as String;
      final fromCity = Cities.byName(origin);
      final toCity = Cities.byName(destination);
      final departure = _date(map['departureTime']);
      final arrival = _date(map['arrivalTime']);
      if (departure == null || arrival == null) return null;

      return BusTrip(
        id: id,
        routeId: (map['routeId'] ?? '') as String,
        operatorId: map['operatorId'] as String,
        operatorName: map['operatorName'] as String,
        serviceClass: (map['serviceClass'] ?? 'Standard') as String,
        operatorRating: (map['operatorRating'] as num?)?.toDouble() ?? 0,
        operatorVerified: (map['operatorVerified'] ?? false) as bool,
        origin: origin,
        fromCode: (map['fromCode'] ?? fromCity?.code ?? _code(origin)) as String,
        fromStation: (map['fromStation'] ?? fromCity?.station ?? origin) as String,
        destination: destination,
        toCode: (map['toCode'] ?? toCity?.code ?? _code(destination)) as String,
        toStation: (map['toStation'] ?? toCity?.station ?? destination) as String,
        departure: departure,
        arrival: arrival,
        price: (map['price'] as num).toInt(),
        taxes: (map['taxes'] as num?)?.toInt() ?? 0,
        serviceFee: (map['serviceFee'] as num?)?.toInt() ?? 0,
        currency: (map['currency'] ?? 'RWF') as String,
        seatsTotal: (map['seatsTotal'] as num).toInt(),
        seatsAvailable: (map['seatsAvailable'] as num).toInt(),
        status: (map['status'] ?? TripStatus.scheduled) as String,
        amenities: {
          for (final code in (map['amenities'] as List? ?? const []))
            if (code is String && Amenity.fromCode(code) != null)
              Amenity.fromCode(code)!,
        },
        stops: [
          for (final raw in (map['stops'] as List? ?? const []))
            if (raw is Map && _date(raw['time']) != null)
              TripStop(
                name: (raw['name'] ?? '') as String,
                time: _date(raw['time'])!,
                note: (raw['note'] ?? '') as String,
              ),
        ],
      );
    } on TypeError {
      return null;
    }
  }

  /// The document body, dates as Firestore timestamps.
  static Map<String, dynamic> toFirestore(BusTrip trip) => {
    'routeId': trip.routeId,
    'operatorId': trip.operatorId,
    'operatorName': trip.operatorName,
    'operatorRating': trip.operatorRating,
    'operatorVerified': trip.operatorVerified,
    'serviceClass': trip.serviceClass,
    'origin': trip.origin,
    'fromCode': trip.fromCode,
    'fromStation': trip.fromStation,
    'destination': trip.destination,
    'toCode': trip.toCode,
    'toStation': trip.toStation,
    'departureTime': Timestamp.fromDate(trip.departure),
    'arrivalTime': Timestamp.fromDate(trip.arrival),
    'price': trip.price,
    'taxes': trip.taxes,
    'serviceFee': trip.serviceFee,
    'currency': trip.currency,
    'seatsTotal': trip.seatsTotal,
    'seatsAvailable': trip.seatsAvailable,
    'status': trip.status,
    'amenities': [for (final a in trip.amenities) a.code],
    'stops': [
      for (final s in trip.stops)
        {'name': s.name, 'time': Timestamp.fromDate(s.time), 'note': s.note},
    ],
  };

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _code(String city) {
    final letters = city.replaceAll(RegExp(r'[^A-Za-z]'), '');
    return (letters.length >= 3 ? letters.substring(0, 3) : letters)
        .toUpperCase();
  }
}
