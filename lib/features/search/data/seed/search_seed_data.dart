// Seed data for the Search feature: operators, routes and trips.
//
// Pure Dart (no Flutter or Firebase imports) so it can be used three ways:
// * by the in-memory repositories in tests and the offline demo;
// * by `dart run tool/export_search_seed.dart`, which writes it to JSON;
// * by `tool/seed/seed_search.js`, which uploads that JSON to Firestore
//   with the Admin SDK (the app itself may not write operators or trips).
//
// Trips are generated relative to a start day, so the data never goes
// stale: re-run the seed and the next N days are filled again. Trip ids
// are predictable (`route_yyyymmdd_hhmm`), so re-seeding overwrites
// instead of duplicating.

import 'package:bookme_summative_project/features/search/domain/entities/city.dart';

/// `operators/{id}`. Field names match `BusOperator.toMap()` and what the
/// Trust Center reads.
const List<Map<String, Object>> seedOperators = [
  {
    'id': 'trinity',
    'name': 'Trinity Express',
    'contactPhone': '+250788300100',
    'rating': 4.6,
    'isVerified': true,
    'refundPolicy':
        '100% refund for operator cancellations or delays over 2 hours.',
  },
  {
    'id': 'jaguar',
    'name': 'Jaguar',
    'contactPhone': '+256414250500',
    'rating': 4.3,
    'isVerified': true,
    'refundPolicy':
        '100% refund for operator cancellations or delays over 2 hours.',
  },
  {
    'id': 'ritco',
    'name': 'RITCO',
    'contactPhone': '+250788150150',
    'rating': 4.4,
    'isVerified': true,
    'refundPolicy':
        '100% refund for operator cancellations or delays over 2 hours.',
  },
  {
    'id': 'volcano',
    'name': 'Volcano Express',
    'contactPhone': '+250788400400',
    'rating': 4.1,
    'isVerified': true,
    'refundPolicy':
        '100% refund for operator cancellations or delays over 2 hours.',
  },
  {
    'id': 'modern_coast',
    'name': 'Modern Coast',
    'contactPhone': '+254709838000',
    'rating': 4.2,
    'isVerified': true,
    'refundPolicy':
        '100% refund for operator cancellations or delays over 2 hours.',
  },
];

/// A border post or other scheduled stop, [afterMinutes] after departure.
class SeedStop {
  const SeedStop(this.name, this.afterMinutes, this.note);

  final String name;
  final int afterMinutes;
  final String note;
}

/// `routes/{id}`: one operator's corridor between two cities.
class SeedRoute {
  const SeedRoute({
    required this.id,
    required this.operatorId,
    required this.from,
    required this.to,
    required this.distanceKm,
    required this.durationMinutes,
    this.stops = const [],
  });

  final String id;
  final String operatorId;
  final City from;
  final City to;
  final int distanceKm;
  final int durationMinutes;
  final List<SeedStop> stops;

  Map<String, Object> toMap() => {
    'id': id,
    'operatorId': operatorId,
    'origin': from.name,
    'destination': to.name,
    'originCountry': from.country,
    'destinationCountry': to.country,
    'distanceKm': distanceKm,
    'durationMinutes': durationMinutes,
  };
}

/// A daily departure on a route.
class SeedDeparture {
  const SeedDeparture({
    required this.routeId,
    required this.hour,
    required this.minute,
    required this.price,
    required this.serviceFee,
    required this.serviceClass,
    required this.amenities,
    this.seatsTotal = 44,
  });

  final String routeId;
  final int hour;
  final int minute;
  final int price;
  final int serviceFee;
  final String serviceClass;
  final List<String> amenities;
  final int seatsTotal;
}

const _borderKatuna = SeedStop(
  'Gatuna / Katuna border',
  150,
  'Scheduled stop · Passport or EAC ID check',
);
const _borderKatunaNorth = SeedStop(
  'Katuna / Gatuna border',
  390,
  'Scheduled stop · Passport or EAC ID check',
);
const _borderMalaba = SeedStop(
  'Malaba border',
  240,
  'Scheduled stop · Passport or EAC ID check',
);
const _borderNimule = SeedStop(
  'Nimule border',
  420,
  'Scheduled stop · Passport, visa and yellow fever card check',
);
const _borderAkanyaru = SeedStop(
  'Akanyaru border',
  120,
  'Scheduled stop · Passport or EAC ID check',
);

const List<SeedRoute> seedRoutes = [
  SeedRoute(
    id: 'trinity_kgl_kla',
    operatorId: 'trinity',
    from: Cities.kigali,
    to: Cities.kampala,
    distanceKm: 510,
    durationMinutes: 570,
    stops: [_borderKatuna],
  ),
  SeedRoute(
    id: 'jaguar_kgl_kla',
    operatorId: 'jaguar',
    from: Cities.kigali,
    to: Cities.kampala,
    distanceKm: 510,
    durationMinutes: 600,
    stops: [_borderKatuna],
  ),
  SeedRoute(
    id: 'ritco_kgl_kla',
    operatorId: 'ritco',
    from: Cities.kigali,
    to: Cities.kampala,
    distanceKm: 510,
    durationMinutes: 570,
    stops: [_borderKatuna],
  ),
  SeedRoute(
    id: 'volcano_kgl_kla',
    operatorId: 'volcano',
    from: Cities.kigali,
    to: Cities.kampala,
    distanceKm: 510,
    durationMinutes: 570,
    stops: [_borderKatuna],
  ),
  SeedRoute(
    id: 'trinity_kla_kgl',
    operatorId: 'trinity',
    from: Cities.kampala,
    to: Cities.kigali,
    distanceKm: 510,
    durationMinutes: 570,
    stops: [_borderKatunaNorth],
  ),
  SeedRoute(
    id: 'jaguar_kla_kgl',
    operatorId: 'jaguar',
    from: Cities.kampala,
    to: Cities.kigali,
    distanceKm: 510,
    durationMinutes: 600,
    stops: [_borderKatunaNorth],
  ),
  SeedRoute(
    id: 'modern_coast_kgl_nbo',
    operatorId: 'modern_coast',
    from: Cities.kigali,
    to: Cities.nairobi,
    distanceKm: 1180,
    durationMinutes: 1500,
    stops: [_borderKatuna],
  ),
  SeedRoute(
    id: 'modern_coast_kla_nbo',
    operatorId: 'modern_coast',
    from: Cities.kampala,
    to: Cities.nairobi,
    distanceKm: 670,
    durationMinutes: 780,
    stops: [_borderMalaba],
  ),
  SeedRoute(
    id: 'jaguar_kla_jub',
    operatorId: 'jaguar',
    from: Cities.kampala,
    to: Cities.juba,
    distanceKm: 650,
    durationMinutes: 720,
    stops: [_borderNimule],
  ),
  SeedRoute(
    id: 'volcano_kgl_bjm',
    operatorId: 'volcano',
    from: Cities.kigali,
    to: Cities.bujumbura,
    distanceKm: 320,
    durationMinutes: 360,
    stops: [_borderAkanyaru],
  ),
  SeedRoute(
    id: 'ritco_kgl_bjm',
    operatorId: 'ritco',
    from: Cities.kigali,
    to: Cities.bujumbura,
    distanceKm: 320,
    durationMinutes: 390,
    stops: [_borderAkanyaru],
  ),
];

const _full = ['wifi', 'ac', 'reclining', 'usb'];
const _standard = ['ac', 'reclining'];

const List<SeedDeparture> seedDepartures = [
  SeedDeparture(
    routeId: 'trinity_kgl_kla',
    hour: 21,
    minute: 0,
    price: 18000,
    serviceFee: 500,
    serviceClass: 'Executive',
    amenities: _full,
  ),
  SeedDeparture(
    routeId: 'trinity_kgl_kla',
    hour: 9,
    minute: 0,
    price: 18000,
    serviceFee: 500,
    serviceClass: 'Executive',
    amenities: _full,
  ),
  SeedDeparture(
    routeId: 'jaguar_kgl_kla',
    hour: 19,
    minute: 0,
    price: 15000,
    serviceFee: 500,
    serviceClass: 'Standard',
    amenities: _standard,
  ),
  SeedDeparture(
    routeId: 'ritco_kgl_kla',
    hour: 22,
    minute: 0,
    price: 17000,
    serviceFee: 500,
    serviceClass: 'Comfort',
    amenities: ['ac', 'reclining'],
  ),
  SeedDeparture(
    routeId: 'volcano_kgl_kla',
    hour: 7,
    minute: 0,
    price: 16000,
    serviceFee: 500,
    serviceClass: 'Executive',
    amenities: ['wifi', 'ac'],
  ),
  SeedDeparture(
    routeId: 'trinity_kla_kgl',
    hour: 20,
    minute: 0,
    price: 65000,
    serviceFee: 2000,
    serviceClass: 'Executive',
    amenities: _full,
  ),
  SeedDeparture(
    routeId: 'jaguar_kla_kgl',
    hour: 8,
    minute: 0,
    price: 55000,
    serviceFee: 2000,
    serviceClass: 'Standard',
    amenities: _standard,
  ),
  SeedDeparture(
    routeId: 'modern_coast_kgl_nbo',
    hour: 6,
    minute: 0,
    price: 45000,
    serviceFee: 500,
    serviceClass: 'Executive',
    amenities: [..._full, 'toilet'],
  ),
  SeedDeparture(
    routeId: 'modern_coast_kla_nbo',
    hour: 18,
    minute: 30,
    price: 90000,
    serviceFee: 2000,
    serviceClass: 'Executive',
    amenities: [..._full, 'toilet'],
  ),
  SeedDeparture(
    routeId: 'jaguar_kla_jub',
    hour: 7,
    minute: 0,
    price: 120000,
    serviceFee: 2000,
    serviceClass: 'Standard',
    amenities: _standard,
  ),
  SeedDeparture(
    routeId: 'volcano_kgl_bjm',
    hour: 8,
    minute: 0,
    price: 10000,
    serviceFee: 500,
    serviceClass: 'Standard',
    amenities: ['ac'],
  ),
  SeedDeparture(
    routeId: 'ritco_kgl_bjm',
    hour: 13,
    minute: 30,
    price: 11000,
    serviceFee: 500,
    serviceClass: 'Comfort',
    amenities: ['ac', 'reclining'],
  ),
];

String _two(int n) => n.toString().padLeft(2, '0');

/// Seats still free, varied but predictable so tests and demos are
/// stable. The Volcano Express 07:00 Kigali → Kampala is always full, to
/// show the waitlist.
int _seatsAvailable(SeedDeparture dep, int dayIndex, int depIndex) {
  if (dep.routeId == 'volcano_kgl_kla') return 0;
  final pattern = (dayIndex * 7 + depIndex * 13) % 10; // 0..9
  if (pattern == 0) return 0;
  return (dep.seatsTotal * pattern / 10).round().clamp(1, dep.seatsTotal);
}

/// Every departure for [days] days starting on [start]'s calendar day.
/// Values are plain Dart (DateTime, List, Map); Firestore conversion is done
/// by the data model or the upload script.
List<Map<String, Object>> generateSeedTrips(DateTime start, {int days = 10}) {
  final routes = {for (final r in seedRoutes) r.id: r};
  final operators = {for (final o in seedOperators) o['id']! as String: o};
  final firstDay = DateTime(start.year, start.month, start.day);
  final trips = <Map<String, Object>>[];

  for (var d = 0; d < days; d++) {
    final day = DateTime(firstDay.year, firstDay.month, firstDay.day + d);
    for (var i = 0; i < seedDepartures.length; i++) {
      final dep = seedDepartures[i];
      final route = routes[dep.routeId]!;
      final op = operators[route.operatorId]!;
      final departure = DateTime(
        day.year,
        day.month,
        day.day,
        dep.hour,
        dep.minute,
      );
      final arrival = departure.add(Duration(minutes: route.durationMinutes));
      final id =
          '${route.id}_${day.year}${_two(day.month)}${_two(day.day)}_${_two(dep.hour)}${_two(dep.minute)}';

      trips.add({
        'id': id,
        'routeId': route.id,
        'operatorId': route.operatorId,
        'operatorName': op['name']!,
        'operatorRating': op['rating']!,
        'operatorVerified': op['isVerified']!,
        'serviceClass': dep.serviceClass,
        'origin': route.from.name,
        'fromCode': route.from.code,
        'fromStation': route.from.station,
        'destination': route.to.name,
        'toCode': route.to.code,
        'toStation': route.to.station,
        'departureTime': departure,
        'arrivalTime': arrival,
        'price': dep.price,
        'taxes': 0,
        'serviceFee': dep.serviceFee,
        'currency': route.from.currency,
        'seatsTotal': dep.seatsTotal,
        'seatsAvailable': _seatsAvailable(dep, d, i),
        'status': 'scheduled',
        'amenities': dep.amenities,
        'stops': [
          for (final stop in route.stops)
            {
              'name': stop.name,
              'time': departure.add(Duration(minutes: stop.afterMinutes)),
              'note': stop.note,
            },
        ],
      });
    }
  }
  return trips;
}

/// Seat numbers `1A`…`11D` (4 per row), the ids of
/// `trips/{tripId}/seats/{seatNumber}`.
List<String> seedSeatNumbers(int seatsTotal) => [
  for (var i = 0; i < seatsTotal; i++) '${i ~/ 4 + 1}${'ABCD'[i % 4]}',
];
