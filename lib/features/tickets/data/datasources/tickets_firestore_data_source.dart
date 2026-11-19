import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/booking/data/models/booking_model.dart';
import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/models/trip_document_mapper.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/date_change.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';

/// Reads the traveller's bookings from Firestore and joins each one with
/// its trip.
///
/// Collections read:
/// * `bookings/{bookingId}`, filtered to the signed-in user (owned by
///   Booking & Payment; this feature reads it and cancels it).
/// * `trips/{tripId}`, owned by Search.
/// * `trips/{tripId}/seats/{seatNumber}`, freed when a booking is
///   cancelled, and taken or freed when it moves to another departure.
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

  /// How many free seats on the new trip are tried before giving up.
  static const int _seatCandidates = 5;

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
    final seatRef = _seatsOf(booking.tripId).doc(booking.seatNumber);

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

  /// Equality filters only, so no composite index is needed. Both trip
  /// field styles are queried, because either may be in the database.
  @override
  Future<List<TripSummary>> findTrips(TripSummary trip) async {
    final results = await Future.wait([
      _trips
          .where('fromStation', isEqualTo: trip.fromStation)
          .where('toStation', isEqualTo: trip.toStation)
          .get(),
      _trips
          .where('origin', isEqualTo: trip.fromStation)
          .where('destination', isEqualTo: trip.toStation)
          .get(),
    ]);
    final byId = <String, TripSummary>{};
    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        final found = _readTrip(doc.id, doc.data());
        if (found != null) byId[doc.id] = found.summary;
      }
    }
    return byId.values.toList();
  }

  /// Like taking a seat in Booking & Payment, a free seat is found first and
  /// then claimed in a transaction; if someone else claims it in between,
  /// the next free seat is tried. The booking, the new seat and the old
  /// seat change together or not at all.
  @override
  Future<Ticket> changeTrip(Ticket ticket, DateChangeQuote quote) async {
    final booking = ticket.booking;
    final newTrip = quote.newTrip;
    final bookingRef = _bookings.doc(booking.id);
    final oldSeatRef = _seatsOf(booking.tripId).doc(booking.seatNumber);

    final free = await _seatsOf(newTrip.tripId)
        .where('status', isEqualTo: 'available')
        .limit(_seatCandidates)
        .get();
    if (free.docs.isEmpty) {
      throw const BookingFailure(
        'This departure is fully booked. Please pick another one.',
      );
    }

    for (final candidate in free.docs) {
      try {
        return await _db.runTransaction((tx) async {
          final bookingSnap = await tx.get(bookingRef);
          final oldSeatSnap = await tx.get(oldSeatRef);
          final newSeatSnap = await tx.get(candidate.reference);

          final current = bookingSnap.data();
          if (current?['status'] != BookingStatus.paid.name ||
              current?['tripId'] != booking.tripId) {
            throw const BookingFailure(
              'This booking was already cancelled or changed.',
            );
          }
          if (newSeatSnap.data()?['status'] != 'available') {
            throw const _SeatTaken();
          }

          final newSeat = newSeatSnap.id;
          tx.update(candidate.reference, {
            'status': 'booked',
            'heldBy': booking.userId,
            'holdExpiresAt': null,
            'bookingId': booking.id,
          });
          if (oldSeatSnap.data()?['bookingId'] == booking.id) {
            tx.update(oldSeatRef, {
              'status': 'available',
              'heldBy': null,
              'holdExpiresAt': null,
              'bookingId': null,
            });
          }
          tx.update(bookingRef, {
            'tripId': newTrip.tripId,
            'seatNumber': newSeat,
            'totalAmount': quote.newTotal,
            'updatedAt': FieldValue.serverTimestamp(),
            // Server timestamps are not allowed inside arrays.
            'changeHistory': FieldValue.arrayUnion([
              {
                'fromTripId': booking.tripId,
                'fromSeat': booking.seatNumber,
                'toTripId': newTrip.tripId,
                'toSeat': newSeat,
                'previousTotal': booking.totalAmount,
                'newTotal': quote.newTotal,
                'refundAmount': quote.refund,
                'changedAt': Timestamp.now(),
              },
            ]),
          });

          return Ticket(
            booking: Booking(
              id: booking.id,
              userId: booking.userId,
              reference: booking.reference,
              tripId: newTrip.tripId,
              seatNumber: newSeat,
              status: booking.status,
              holdExpiresAt: booking.holdExpiresAt,
              totalAmount: quote.newTotal,
              currency: booking.currency,
              createdAt: booking.createdAt,
              passenger: booking.passenger,
              paymentId: booking.paymentId,
            ),
            trip: newTrip,
          );
        });
      } on _SeatTaken {
        continue;
      }
    }
    throw const BookingFailure(
      'The last seats on this departure were just taken. Please pick '
      'another one.',
    );
  }

  CollectionReference<Map<String, dynamic>> _seatsOf(String tripId) =>
      _trips.doc(tripId).collection('seats');

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

/// Another traveller claimed the seat while we were moving onto it.
class _SeatTaken implements Exception {
  const _SeatTaken();
}
