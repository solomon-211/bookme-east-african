import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bus_operator.dart';
import '../models/bus_route.dart';
import '../models/trip.dart';

class TripRepository {
  TripRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ------------------------------------------------------------------ Read

  /// Trips for origin -> destination on [date] that are still bookable.
  /// Filtering by date happens client-side so no composite index is needed.
  Future<List<Trip>> searchTrips({
    required String origin,
    required String destination,
    required DateTime date,
  }) async {
    final snap = await _db
        .collection('trips')
        .where('origin', isEqualTo: origin)
        .where('destination', isEqualTo: destination)
        .get();
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final now = DateTime.now();
    final trips = snap.docs
        .map(Trip.fromDoc)
        .where((t) =>
            !t.departureTime.isBefore(start) &&
            t.departureTime.isBefore(end) &&
            t.departureTime.isAfter(now) &&
            t.status != TripStatus.cancelled)
        .toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));
    return trips;
  }

  /// Live updates so "seats left" reflects other travelers' bookings.
  Stream<Trip?> watchTrip(String id) => _db
      .collection('trips')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Trip.fromDoc(d) : null);

  Future<BusOperator?> getOperator(String id) async {
    final d = await _db.collection('operators').doc(id).get();
    return d.exists ? BusOperator.fromDoc(d) : null;
  }

  Future<BusRoute?> getRoute(String id) async {
    final d = await _db.collection('routes').doc(id).get();
    return d.exists ? BusRoute.fromDoc(d) : null;
  }

  // ---------------------------------------------------------------- Create

  /// Creates demo operators, routes and the next 5 days of trips.
  /// Existing trips are left untouched (their seat data is preserved).
  /// Returns the number of new trips created.
  Future<int> seedDemoData() async {
    final operators = <String, BusOperator>{
      'trinity': const BusOperator(
        id: 'trinity',
        name: 'Trinity Express',
        contactPhone: '+250788000001',
        rating: 4.6,
        isVerified: true,
        refundPolicy: '100% refund for operator cancellations or delays over 2 hours.',
      ),
      'volcano': const BusOperator(
        id: 'volcano',
        name: 'Volcano Express',
        contactPhone: '+250788000002',
        rating: 4.3,
        isVerified: true,
        refundPolicy: '100% refund for operator cancellations or delays over 2 hours.',
      ),
      'jaguar': const BusOperator(
        id: 'jaguar',
        name: 'Jaguar Executive',
        contactPhone: '+254700000003',
        rating: 4.1,
        isVerified: true,
        refundPolicy: '100% refund for operator cancellations or delays over 2 hours.',
      ),
    };

    // routeId, operatorId, origin, destination, originCountry, destCountry,
    // km, minutes, price, currency
    const routeSeeds = <List<Object>>[
      ['kgl-kla-trinity', 'trinity', 'Kigali', 'Kampala', 'Rwanda', 'Uganda', 510, 570, 22000, 'RWF'],
      ['kla-kgl-trinity', 'trinity', 'Kampala', 'Kigali', 'Uganda', 'Rwanda', 510, 570, 22000, 'RWF'],
      ['kgl-kla-volcano', 'volcano', 'Kigali', 'Kampala', 'Rwanda', 'Uganda', 510, 600, 20000, 'RWF'],
      ['kla-kgl-volcano', 'volcano', 'Kampala', 'Kigali', 'Uganda', 'Rwanda', 510, 600, 20000, 'RWF'],
      ['kla-nbo-jaguar', 'jaguar', 'Kampala', 'Nairobi', 'Uganda', 'Kenya', 660, 780, 80000, 'UGX'],
      ['nbo-kla-jaguar', 'jaguar', 'Nairobi', 'Kampala', 'Kenya', 'Uganda', 660, 780, 5500, 'KES'],
      ['kgl-bjm-volcano', 'volcano', 'Kigali', 'Bujumbura', 'Rwanda', 'Burundi', 270, 360, 15000, 'RWF'],
      ['bjm-kgl-volcano', 'volcano', 'Bujumbura', 'Kigali', 'Burundi', 'Rwanda', 270, 360, 15000, 'RWF'],
    ];
    const departureHours = [6, 9, 21];
    const seatsTotal = 30;

    final batch = _db.batch();
    for (final op in operators.values) {
      batch.set(_db.collection('operators').doc(op.id), op.toMap());
    }

    final today = DateTime.now();
    final tripsToCreate = <Trip>[];
    final routes = <BusRoute>[];
    for (final s in routeSeeds) {
      final route = BusRoute(
        id: s[0] as String,
        operatorId: s[1] as String,
        origin: s[2] as String,
        destination: s[3] as String,
        originCountry: s[4] as String,
        destinationCountry: s[5] as String,
        distanceKm: s[6] as int,
        durationMinutes: s[7] as int,
      );
      routes.add(route);
      batch.set(_db.collection('routes').doc(route.id), route.toMap());

      for (var day = 0; day < 5; day++) {
        for (final hour in departureHours) {
          final base = DateTime(today.year, today.month, today.day + day);
          final departure = base.add(Duration(hours: hour));
          if (!departure.isAfter(today)) continue;
          final stamp = '${base.year}${base.month.toString().padLeft(2, '0')}'
              '${base.day.toString().padLeft(2, '0')}';
          tripsToCreate.add(Trip(
            id: '${route.id}_${stamp}_$hour',
            routeId: route.id,
            operatorId: route.operatorId,
            operatorName: operators[route.operatorId]!.name,
            origin: route.origin,
            destination: route.destination,
            departureTime: departure,
            arrivalTime: departure.add(Duration(minutes: route.durationMinutes)),
            price: s[8] as int,
            currency: s[9] as String,
            seatsTotal: seatsTotal,
            seatsAvailable: seatsTotal,
            status: TripStatus.scheduled,
          ));
        }
      }
    }

    // Only create trips that do not exist yet, so live seat data is kept.
    final existing = await Future.wait(
      tripsToCreate.map((t) => _db.collection('trips').doc(t.id).get()),
    );
    var created = 0;
    for (var i = 0; i < tripsToCreate.length; i++) {
      if (existing[i].exists) continue;
      batch.set(_db.collection('trips').doc(tripsToCreate[i].id),
          tripsToCreate[i].toMap());
      created++;
    }
    await batch.commit();
    return created;
  }
}
