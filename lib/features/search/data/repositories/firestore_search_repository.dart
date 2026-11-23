import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/data/models/bus_operator.dart';
import 'package:bookme_summative_project/features/search/data/models/bus_trip_model.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/search_repository.dart';

/// Reads `operators` and `trips` from Firestore.
class FirestoreSearchRepository implements SearchRepository {
  FirestoreSearchRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _trips =>
      _db.collection('trips');

  /// Composite index (firestore.indexes.json):
  /// origin ASC, destination ASC, departureTime ASC.
  @override
  Future<List<BusTrip>> searchTrips({
    required String origin,
    required String destination,
    required DateTime from,
    required DateTime to,
  }) => _guard(() async {
    final snapshot = await _trips
        .where('origin', isEqualTo: origin)
        .where('destination', isEqualTo: destination)
        .where(
          'departureTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        )
        .where('departureTime', isLessThan: Timestamp.fromDate(to))
        .orderBy('departureTime')
        .get();
    return [
      for (final doc in snapshot.docs)
        ?BusTripModel.fromMap(doc.id, doc.data()),
    ];
  });

  @override
  Future<BusTrip?> tripById(String tripId) => _guard(() async {
    final doc = await _trips.doc(tripId).get();
    final data = doc.data();
    return data == null ? null : BusTripModel.fromMap(doc.id, data);
  });

  @override
  Future<List<BusOperator>> operators() => _guard(() async {
    final snapshot = await _db.collection('operators').orderBy('name').get();
    return [for (final doc in snapshot.docs) BusOperator.fromDoc(doc)];
  });

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseException catch (e) {
      throw SearchFailure(_message(e));
    }
  }

  static String _message(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
        return 'You seem to be offline. Check your connection and try again.';
      case 'permission-denied':
      case 'unauthenticated':
        return 'Please sign in again to search for buses.';
      case 'failed-precondition':
        // The composite index is missing or still building.
        return 'Search is being set up. Please try again in a few minutes.';
      default:
        return 'We couldn\'t load buses right now. Please try again.';
    }
  }
}
