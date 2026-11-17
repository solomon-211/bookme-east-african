import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';

/// Converts a `trips/{tripId}` document into a [TripSummary].
///
/// Two field naming styles exist in the team's code, so both are accepted:
/// * booking style: `fromCode`, `fromStation`, `departure`, `baseFare`, ...
/// * search style: `origin`, `destination`, `departureTime`, `price`, ...
///
/// Returns `null` when a required field is missing, so one bad document
/// hides one ticket instead of breaking the whole My Trips list.
class TripDocumentMapper {
  const TripDocumentMapper._();

  static const Map<String, String> _cityCodes = {
    'kigali': 'KGL',
    'kampala': 'KLA',
    'nairobi': 'NBO',
    'juba': 'JUB',
    'dar es salaam': 'DAR',
    'bujumbura': 'BJM',
    'goma': 'GOM',
    'arusha': 'ARK',
  };

  static TripSummary? fromMap(String id, Map<String, dynamic> map) {
    final origin = _string(map, ['fromStation', 'origin']);
    final destination = _string(map, ['toStation', 'destination']);
    final departure = _date(map, ['departure', 'departureTime']);
    final arrival = _date(map, ['arrival', 'arrivalTime']);
    final fare = _int(map, ['baseFare', 'price']);
    if (origin == null ||
        destination == null ||
        departure == null ||
        arrival == null ||
        fare == null) {
      return null;
    }

    return TripSummary(
      tripId: id,
      operatorName: _string(map, ['operatorName']) ?? 'BookMe partner',
      fromCode: _string(map, ['fromCode']) ?? cityCode(origin),
      fromStation: origin,
      toCode: _string(map, ['toCode']) ?? cityCode(destination),
      toStation: destination,
      departure: departure,
      arrival: arrival,
      durationLabel:
          _string(map, ['durationLabel']) ??
          durationLabel(arrival.difference(departure)),
      baseFare: fare,
      taxes: _int(map, ['taxes']) ?? 0,
      serviceFee: _int(map, ['serviceFee']) ?? 0,
      currency: _string(map, ['currency']) ?? 'RWF',
    );
  }

  /// `Kigali` → `KGL`. Unknown cities use their first three letters.
  static String cityCode(String place) {
    final city = place.split(RegExp(r'[-,–]')).first.trim().toLowerCase();
    final known = _cityCodes[city];
    if (known != null) return known;
    final letters = city.replaceAll(RegExp(r'[^a-z]'), '');
    return (letters.length >= 3 ? letters.substring(0, 3) : letters)
        .toUpperCase();
  }

  /// `Duration(hours: 9, minutes: 30)` → `9h 30m`.
  static String durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  static String? _string(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static int? _int(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toInt();
    }
    return null;
  }

  static DateTime? _date(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
    }
    return null;
  }
}
