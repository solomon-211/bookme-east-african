import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/passenger.dart';

/// Converts between [Booking] and the `bookings/{bookingId}` document.
class BookingModel {
  const BookingModel._();

  static Map<String, dynamic> toMap(Booking booking) {
    return {
      'userId': booking.userId,
      'reference': booking.reference,
      'tripId': booking.tripId,
      'seatNumber': booking.seatNumber,
      'status': booking.status.name,
      'holdExpiresAt': Timestamp.fromDate(booking.holdExpiresAt),
      'totalAmount': booking.totalAmount,
      'currency': booking.currency,
      'createdAt': Timestamp.fromDate(booking.createdAt),
      'passenger': booking.passenger == null
          ? null
          : passengerToMap(booking.passenger!),
      'paymentId': booking.paymentId,
    };
  }

  static Booking fromMap(String id, Map<String, dynamic> map) {
    final rawPassenger = map['passenger'];
    final passengerMap = rawPassenger is Map
        ? Map<String, dynamic>.from(rawPassenger)
        : null;
    return Booking(
      id: id,
      userId: map['userId'] as String,
      reference: map['reference'] as String,
      tripId: map['tripId'] as String,
      seatNumber: map['seatNumber'] as String,
      status: BookingStatus.fromName(map['status'] as String?),
      holdExpiresAt: (map['holdExpiresAt'] as Timestamp).toDate(),
      totalAmount: (map['totalAmount'] as num).toInt(),
      currency: map['currency'] as String? ?? 'RWF',
      createdAt: _readDate(map['createdAt']),
      passenger: passengerMap == null ? null : passengerFromMap(passengerMap),
      paymentId: map['paymentId'] as String?,
    );
  }

  static Map<String, dynamic> passengerToMap(Passenger passenger) {
    return {
      'fullName': passenger.fullName,
      'phone': passenger.phone,
      'idNumber': passenger.idNumber,
      'nationality': passenger.nationality,
      'email': passenger.email,
    };
  }

  static Passenger passengerFromMap(Map<String, dynamic> map) {
    return Passenger(
      fullName: map['fullName'] as String,
      phone: map['phone'] as String,
      idNumber: map['idNumber'] as String,
      nationality: map['nationality'] as String,
      email: map['email'] as String?,
    );
  }

  /// `serverTimestamp()` is null in the local cache until the write is
  /// confirmed, so fall back to "now" instead of crashing.
  static DateTime _readDate(Object? value) =>
      value is Timestamp ? value.toDate() : DateTime.now();
}
