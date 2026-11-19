import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/booking/data/models/booking_model.dart';
import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/models/trip_document_mapper.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';

/// Reads the traveller's bookings from Firestore and joins each one with
/// its trip.
///
/// Collections read:
/// * `bookings/{bookingId}`, filtered to the signed-in user (owned by
///   Booking & Payment; this feature reads it and cancels it).
/// * `trips/{tripId}`, owned by Search.
/// * `trips/{tripId}/seats/{seatNumber}`, freed when a booking is
///   cancelled.
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
                Ticket(
                  booking: booking,
                  trip: trip.summary,
                  tripStatus: trip.status,
                ),
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
          return Ticket(
            booking: booking,
            trip: trip.summary,
            tripStatus: trip.status,
          );
        });
  }

  /// Runs as one transaction, so the booking is never cancelled without
  /// its seat being freed (or the other way round). The seat is only freed
  /// if it still belongs to this booking.
  @override
  Future<void> cancelBooking(Ticket ticket, RefundQuote refund) {
    final booking = ticket.booking;
    final bookingRef = _bookings.doc(booking.id);
    final seatRef = _trips
        .doc(booking.tripId)
        .collection('seats')
        .doc(booking.seatNumber);

    return _db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      final seatSnap = await tx.get(seatRef);

      if (bookingSnap.data()?['status'] != BookingStatus.paid.name) {
        throw const BookingFailure(
          'This booking was already cancelled or changed.',
        );
      }

      if (seatSnap.data()?['bookingId'] == booking.id) {
        tx.update(seatRef, {
          'status': 'available',
          'heldBy': null,
          'holdExpiresAt': null,
          'bookingId': null,
        });
      }
      tx.update(bookingRef, {
        'status': BookingStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'refundAmount': refund.refund,
        'refundReason': refund.reason.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> deleteBooking(String bookingId) =>
      _bookings.doc(bookingId).delete();

  Future<_TripDoc> _fetchTrip(Booking booking) async {
    final doc = await _trips.doc(booking.tripId).get();
    final data = doc.data();
    final trip = data == null ? null : _readTrip(doc.id, data);
    if (trip == null) {
      throw const BookingFailure(
        'We couldn\'t load the trip for this ticket. Please try again.',
      );
    }
    return trip;
  }

  /// Loads every trip in [tripIds] in as few reads as possible.
  Future<Map<String, _TripDoc>> _fetchTrips(Iterable<String> tripIds) async {
    final ids = tripIds.toSet().toList();
    final result = <String, _TripDoc>{};

    for (var start = 0; start < ids.length; start += _whereInLimit) {
      final end = (start + _whereInLimit).clamp(0, ids.length);
      final snapshot = await _trips
          .where(FieldPath.documentId, whereIn: ids.sublist(start, end))
          .get();
      for (final doc in snapshot.docs) {
        final trip = _readTrip(doc.id, doc.data());
        if (trip != null) result[doc.id] = trip;
      }
    }
    return result;
  }

  _TripDoc? _readTrip(String id, Map<String, dynamic> data) {
    final summary = TripDocumentMapper.fromMap(id, data);
    if (summary == null) return null;
    return (
      summary: summary,
      status: TripStatus.fromName(data['status'] as String?),
    );
  }
}

/// A trip document read from Firestore: the summary plus its live status.
typedef _TripDoc = ({TripSummary summary, TripStatus status});
