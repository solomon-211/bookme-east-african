import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/trip.dart';

class BookingFailure implements Exception {
  const BookingFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class BookingRepository {
  BookingRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw BookingFailure(
          e.code == 'unavailable' || e.code == 'network-request-failed'
              ? 'No connection. Check your internet and retry.'
              : 'Something went wrong (${e.code}). Please try again.');
    }
  }

  // ---------------------------------------------------------------- Create

  /// Atomically takes one seat from [trip] and creates the booking.
  /// A transaction guarantees the seat count never goes below zero, even if
  /// two travelers book the last seat at the same moment.
  /// Payment is simulated: the booking is recorded as paid.
  Future<String> createBooking({
    required Trip trip,
    required String userId,
    required String passengerName,
    required String passengerPhone,
    required String paymentMethod,
  }) =>
      _guard(() async {
        final tripRef = _db.collection('trips').doc(trip.id);
        final bookingRef = _bookings.doc();

        await _db.runTransaction((tx) async {
          final snap = await tx.get(tripRef);
          if (!snap.exists) {
            throw const BookingFailure('This trip no longer exists.');
          }
          final current = Trip.fromDoc(snap);
          if (current.status == TripStatus.cancelled) {
            throw const BookingFailure('This trip was cancelled.');
          }
          if (!current.departureTime.isAfter(DateTime.now())) {
            throw const BookingFailure('This trip has already departed.');
          }
          if (current.seatsAvailable <= 0) {
            throw const BookingFailure('Sorry, this trip just sold out.');
          }

          tx.update(tripRef, {
            'seatsAvailable': FieldValue.increment(-1),
          });
          tx.set(bookingRef, {
            'userId': userId,
            'tripId': current.id,
            'passengerName': passengerName.trim(),
            'passengerPhone': passengerPhone.trim(),
            'amount': current.price,
            'currency': current.currency,
            'paymentMethod': paymentMethod,
            'paymentStatus': PaymentStatus.paid,
            'status': BookingStatus.confirmed,
            'ticketCode': 'BME-${bookingRef.id.substring(0, 6).toUpperCase()}',
            'origin': current.origin,
            'destination': current.destination,
            'operatorName': current.operatorName,
            'departureTime': Timestamp.fromDate(current.departureTime),
            'arrivalTime': Timestamp.fromDate(current.arrivalTime),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
        return bookingRef.id;
      });

  // ------------------------------------------------------------------ Read

  /// Live list of the user's bookings, soonest departure first.
  /// Sorted client-side so no composite index is required.
  Stream<List<Booking>> watchUserBookings(String userId) => _bookings
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs.map(Booking.fromDoc).toList()
        ..sort((a, b) => a.departureTime.compareTo(b.departureTime)));

  Stream<Booking?> watchBooking(String id) => _bookings
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Booking.fromDoc(d) : null);

  // ---------------------------------------------------------------- Update

  Future<void> updatePassenger({
    required String bookingId,
    required String passengerName,
    required String passengerPhone,
  }) =>
      _guard(() => _bookings.doc(bookingId).update({
            'passengerName': passengerName.trim(),
            'passengerPhone': passengerPhone.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          }));

  /// Cancels an active booking, returns its seat to the trip and marks the payment refunded
  /// (simulated refund).
  Future<void> cancelBooking(String bookingId) => _guard(() async {
        final bookingRef = _bookings.doc(bookingId);
        await _db.runTransaction((tx) async {
          final bSnap = await tx.get(bookingRef);
          if (!bSnap.exists) {
            throw const BookingFailure('This booking no longer exists.');
          }
          final booking = Booking.fromDoc(bSnap);
          if (booking.status == BookingStatus.cancelled) return;
          if (!booking.departureTime.isAfter(DateTime.now())) {
            throw const BookingFailure(
                'This trip has already departed and cannot be cancelled.');
          }
          final tripRef = _db.collection('trips').doc(booking.tripId);
          final tSnap = await tx.get(tripRef);
          if (tSnap.exists) {
            tx.update(tripRef, {
              'seatsAvailable': FieldValue.increment(1),
            });
          }
          tx.update(bookingRef, {
            'status': BookingStatus.cancelled,
            'paymentStatus': PaymentStatus.refunded,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      });

  // ---------------------------------------------------------------- Delete

  /// Removes a booking record. Active bookings must be cancelled first.
  Future<void> deleteBooking(String bookingId) => _guard(() async {
        final doc = _bookings.doc(bookingId);
        final snap = await doc.get();
        if (snap.exists && Booking.fromDoc(snap).isActive) {
          throw const BookingFailure('Cancel this booking before deleting it.');
        }
        await doc.delete();
      });

  /// Used when a user deletes their account: cancels active bookings
  /// (returning seats) then deletes every booking record.
  Future<void> deleteAllForUser(String userId) => _guard(() async {
        final snap = await _bookings.where('userId', isEqualTo: userId).get();
        for (final doc in snap.docs) {
          final booking = Booking.fromDoc(doc);
          if (booking.isActive) await cancelBooking(booking.id);
          await doc.reference.delete();
        }
      });
}
