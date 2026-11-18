import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/booking/data/datasources/booking_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/models/booking_model.dart';
import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/passenger.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/booking/domain/utils/booking_reference.dart';

/// Thrown inside a transaction when another traveller grabbed the seat
/// between our query and our transaction. We catch it and try the next seat.
class _SeatTaken implements Exception {
  const _SeatTaken();
}

/// Firestore access for seat holds and bookings.
///
/// Collections used:
/// * `trips/{tripId}/seats/{seatNumber}` – one doc per seat (owned by the
///   Foundations/Search features; we only change `status`, `heldBy`,
///   `holdExpiresAt` and `bookingId`).
/// * `bookings/{bookingId}` – owned by this feature.
class BookingFirestoreDataSource implements BookingDataSource {
  BookingFirestoreDataSource({
    required FirebaseFirestore firestore,
    required this._currentUserId,
    DateTime Function()? clock,
    this._random,
  }) : _db = firestore,
       _now = clock ?? DateTime.now;

  final FirebaseFirestore _db;
  final String? Function() _currentUserId;
  final DateTime Function() _now;
  final Random? _random;

  /// How many candidate seats we try before saying the bus is full.
  static const int _candidateLimit = 5;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  CollectionReference<Map<String, dynamic>> _seats(String tripId) =>
      _db.collection('trips').doc(tripId).collection('seats');

  String get _uid {
    final uid = _currentUserId();
    if (uid == null) {
      throw const BookingFailure('Please sign in again to continue booking.');
    }
    return uid;
  }

  /// Finds a free seat (or one whose hold has run out) and reserves it in a
  /// transaction, so two people can never hold the same seat.
  @override
  Future<Booking> holdSeat(TripSummary trip) async {
    final uid = _uid;
    final now = _now();

    final free = await _seats(trip.tripId)
        .where('status', isEqualTo: 'available')
        .limit(_candidateLimit)
        .get();

    final candidates = [...free.docs, ...await _staleHolds(trip.tripId, now)];
    if (candidates.isEmpty) {
      throw const BookingFailure(
        'This bus is fully booked. Join the waitlist and we\'ll alert you '
        'if a seat opens.',
      );
    }

    for (final candidate in candidates) {
      try {
        return await _db.runTransaction((tx) async {
          final snapshot = await tx.get(candidate.reference);
          final data = snapshot.data();
          if (data == null || !_isSeatFree(data, _now())) {
            throw const _SeatTaken();
          }

          final seatNumber = snapshot.id;
          final bookingRef = _bookings.doc();
          final createdAt = _now();
          final booking = Booking(
            id: bookingRef.id,
            userId: uid,
            reference: generateBookingReference(seatNumber, random: _random),
            tripId: trip.tripId,
            seatNumber: seatNumber,
            status: BookingStatus.held,
            holdExpiresAt: createdAt.add(kSeatHoldDuration),
            totalAmount: trip.total,
            currency: trip.currency,
            createdAt: createdAt,
          );

          tx.update(candidate.reference, {
            'status': 'held',
            'heldBy': uid,
            'holdExpiresAt': Timestamp.fromDate(booking.holdExpiresAt),
            'bookingId': booking.id,
          });
          tx.set(bookingRef, BookingModel.toMap(booking));
          return booking;
        });
      } on _SeatTaken {
        continue;
      }
    }

    throw const BookingFailure(
      'The last seats were just taken. Please try another departure.',
    );
  }

  /// Seats whose hold has run out, so they can be re-claimed.
  ///
  /// Needs the composite index (status ASC, holdExpiresAt ASC). Until that
  /// index is deployed Firestore answers `failed-precondition`; we then fall
  /// back to free seats only instead of failing the whole booking.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _staleHolds(
    String tripId,
    DateTime now,
  ) async {
    try {
      final stale = await _seats(tripId)
          .where('status', isEqualTo: 'held')
          .where('holdExpiresAt', isLessThan: Timestamp.fromDate(now))
          .limit(_candidateLimit)
          .get();
      return stale.docs;
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') return const [];
      rethrow;
    }
  }

  bool _isSeatFree(Map<String, dynamic> seat, DateTime now) {
    final status = seat['status'] as String?;
    if (status == 'available') return true;
    final heldUntil = seat['holdExpiresAt'];
    return status == 'held' &&
        heldUntil is Timestamp &&
        heldUntil.toDate().isBefore(now);
  }

  @override
  Stream<Booking> watchBooking(String bookingId) {
    return _bookings
        .doc(bookingId)
        .snapshots()
        .where((snap) => snap.exists && snap.data() != null)
        .map((snap) => BookingModel.fromMap(snap.id, snap.data()!));
  }

  @override
  Future<void> savePassenger(String bookingId, Passenger passenger) {
    return _bookings.doc(bookingId).update({
      'passenger': BookingModel.passengerToMap(passenger),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Keeps the seat reserved longer, used while someone else pays.
  @override
  Future<Booking> extendHold(Booking booking, DateTime until) async {
    final batch = _db.batch()
      ..update(_bookings.doc(booking.id), {
        'holdExpiresAt': Timestamp.fromDate(until),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(_seats(booking.tripId).doc(booking.seatNumber), {
        'holdExpiresAt': Timestamp.fromDate(until),
      });
    await batch.commit();
    return booking.copyWith(holdExpiresAt: until);
  }

  /// Marks the booking expired and frees the seat, but only while the
  /// booking is still an unpaid hold. A payment that lands at the same moment
  /// wins: if the booking is already `paid` nothing is changed, and if
  /// another traveller has re-held the seat we leave their hold alone.
  @override
  Future<void> releaseHold(Booking booking) async {
    final seatRef = _seats(booking.tripId).doc(booking.seatNumber);
    final bookingRef = _bookings.doc(booking.id);
    await _db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      final seatSnap = await tx.get(seatRef);

      if (bookingSnap.data()?['status'] != BookingStatus.held.name) return;

      final seatStillOurs =
          seatSnap.data()?['bookingId'] == booking.id &&
          seatSnap.data()?['status'] == 'held';
      if (seatStillOurs) {
        tx.update(seatRef, {
          'status': 'available',
          'heldBy': null,
          'holdExpiresAt': null,
          'bookingId': null,
        });
      }
      tx.update(bookingRef, {
        'status': BookingStatus.expired.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
