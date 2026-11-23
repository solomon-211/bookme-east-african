import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookme_summative_project/features/search/data/models/bus_trip_model.dart';
import 'package:bookme_summative_project/features/search/data/repositories/in_memory_search_repositories.dart';
import 'package:bookme_summative_project/features/search/data/seed/search_seed_data.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/tickets/data/models/trip_document_mapper.dart';

void main() {
  final start = DateTime(2026, 10, 1);
  final trip = InMemorySearchRepository.seedTrips(
    start,
    days: 1,
  ).firstWhere((t) => t.routeId == 'trinity_kgl_kla' && t.departure.hour == 21);

  test('Firestore map round-trips', () {
    final map = BusTripModel.toFirestore(trip);
    expect(map['departureTime'], isA<Timestamp>());
    expect(BusTripModel.fromMap(trip.id, map), trip);
  });

  test('Tickets reads the same document as the booking flow expects', () {
    final summary = TripDocumentMapper.fromMap(
      trip.id,
      BusTripModel.toFirestore(trip),
    );
    expect(summary, trip.toSummary());
    expect(summary!.fromCode, 'KGL');
    expect(summary.fromStation, 'Nyabugogo');
    expect(summary.total, 18500);
    expect(summary.durationLabel, '9h 30m');
  });

  test('a document missing required fields is skipped, not thrown', () {
    expect(BusTripModel.fromMap('x', {'origin': 'Kigali'}), isNull);
  });

  test('unknown amenity codes are ignored', () {
    final map = BusTripModel.toFirestore(trip)
      ..['amenities'] = ['wifi', 'jacuzzi'];
    expect(BusTripModel.fromMap(trip.id, map)!.amenities, {Amenity.wifi});
  });

  test('seed ids are predictable so re-seeding overwrites', () {
    expect(trip.id, 'trinity_kgl_kla_20261001_2100');
    final again = generateSeedTrips(start, days: 1).map((m) => m['id']);
    expect(again.toSet(), hasLength(seedDepartures.length));
  });

  test('seed seat numbers are 4 per row', () {
    expect(seedSeatNumbers(6), ['1A', '1B', '1C', '1D', '2A', '2B']);
  });
}
