import 'package:bookme_summative_project/data/models/bus_operator.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';

/// Thrown by the Search repositories with a message safe to show.
class SearchFailure implements Exception {
  const SearchFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Read-only access to operators and trips.
abstract class SearchRepository {
  /// Trips from [origin] to [destination] leaving in `[from, to)`, by
  /// departure time. One Firestore query (composite index
  /// origin + destination + departureTime).
  Future<List<BusTrip>> searchTrips({
    required String origin,
    required String destination,
    required DateTime from,
    required DateTime to,
  });

  /// Re-reads one trip, e.g. for live seats on Trip Details.
  Future<BusTrip?> tripById(String tripId);

  /// Every operator, by name.
  Future<List<BusOperator>> operators();
}
