import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/booking/data/models/booking_model.dart';
import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/models/trip_document_mapper.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

/// Reads the traveller's bookings from Firestore and joins each one with
/// its trip.
///
/// Collections read:
/// * `bookings/{bookingId}`, filtered to the signed-in user (owned by
///   Booking & Payment; this feature only reads and, later, updates it).
/// * `trips/{tripId}`, owned by Search.
///
/// The bookings query uses only equality / `in` filters, so Firestore can
/// answer it without a composite index. Sorting by departure happens here,
/// because the departure time lives on the trip, not on the booking.
class TicketsFirestoreDataSource implements TicketsDataSource {
  TicketsFirestoreDataSource({
    required FirebaseFirestore firestore,
    required this._currentUserId,
  }) : _db = firestore;

  final FirebaseFirestore _db;
  final String? Function() _currentUserId;

  /// Firestore allows at most 30 values in one `whereIn` filter.
  static const int _whereInLimit = 30;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  CollectionReference<Map<String, dynamic>> get _trips =>
      _db.collection('trips');

  @override
  Stream<List<Ticket>> watchMyTickets() {
    final uid = _currentUserId();
    if (uid == null) {
      return Stream.error(
        const BookingFailure('Please sign in to see your trips.'),
      );
    }

    return _bookings
        .where('userId', isEqualTo: uid)
        .where(
          'status',
          whereIn: Ticket.listedStatuses.map((s) => s.name).toList(),
        )
        .snapshots()
        .asyncMap((snapshot) async {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.id, doc.data()))
              .toList();
          final trips = await _fetchTrips(bookings.map((b) => b.tripId));

          final tickets = <Ticket>[
            for (final booking in bookings)
              if (trips[booking.tripId] case final trip?)
                Ticket(booking: booking, trip: trip),
          ];
          tickets.sort((a, b) => b.trip.departure.compareTo(a.trip.departure));
          return tickets;
        });
  }

  @override
  Stream<Ticket> watchTicket(String bookingId) {
    return _bookings
        .doc(bookingId)
        .snapshots()
        .where((snap) => snap.exists && snap.data() != null)
        .asyncMap((snap) async {
          final booking = BookingModel.fromMap(snap.id, snap.data()!);
          final trip = await _fetchTrip(booking);
          return Ticket(booking: booking, trip: trip);
        });
  }

  Future<TripSummary> _fetchTrip(Booking booking) async {
    final doc = await _trips.doc(booking.tripId).get();
    final data = doc.data();
    final trip = data == null ? null : TripDocumentMapper.fromMap(doc.id, data);
    if (trip == null) {
      throw const BookingFailure(
        'We couldn\'t load the trip for this ticket. Please try again.',
      );
    }
    return trip;
  }

  /// Loads every trip in [tripIds] in as few reads as possible.
  Future<Map<String, TripSummary>> _fetchTrips(Iterable<String> tripIds) async {
    final ids = tripIds.toSet().toList();
    final result = <String, TripSummary>{};

    for (var start = 0; start < ids.length; start += _whereInLimit) {
      final end = (start + _whereInLimit).clamp(0, ids.length);
      final snapshot = await _trips
          .where(FieldPath.documentId, whereIn: ids.sublist(start, end))
          .get();
      for (final doc in snapshot.docs) {
        final trip = TripDocumentMapper.fromMap(doc.id, doc.data());
        if (trip != null) result[doc.id] = trip;
      }
    }
    return result;
  }
}
