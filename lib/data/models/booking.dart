import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BookingStatus {
  static const confirmed = 'confirmed';
  static const cancelled = 'cancelled';
}

class PaymentStatus {
  static const pending = 'pending';
  static const paid = 'paid';
  static const refunded = 'refunded';
}

/// Firestore: bookings/{bookingId}. One seat on one trip for one user.
/// Seats are not individually assigned: a booking just takes one from the
/// trip's `seatsAvailable` count.
///
/// origin, destination, operatorName, departureTime and arrivalTime are
/// denormalized from the trip so "My Trips" renders without extra reads.
class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.passengerName,
    required this.passengerPhone,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.ticketCode,
    required this.origin,
    required this.destination,
    required this.operatorName,
    required this.departureTime,
    required this.arrivalTime,
    this.createdAt,
  });

  final String id;
  final String userId; // FK -> users
  final String tripId; // FK -> trips
  final String passengerName;
  final String passengerPhone;
  final int amount;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String ticketCode;
  final String origin;
  final String destination;
  final String operatorName;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final DateTime? createdAt;

  /// Confirmed and not yet departed: can still be edited or cancelled.
  bool get isActive =>
      status == BookingStatus.confirmed && departureTime.isAfter(DateTime.now());

  String get displayStatus {
    if (status == BookingStatus.cancelled) return 'Cancelled';
    return departureTime.isAfter(DateTime.now()) ? 'Confirmed' : 'Completed';
  }

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Booking(
      id: doc.id,
      userId: d['userId'] as String,
      tripId: d['tripId'] as String,
      passengerName: d['passengerName'] as String,
      passengerPhone: (d['passengerPhone'] ?? '') as String,
      amount: (d['amount'] as num).toInt(),
      currency: d['currency'] as String,
      paymentMethod: d['paymentMethod'] as String,
      paymentStatus: d['paymentStatus'] as String,
      status: d['status'] as String,
      ticketCode: d['ticketCode'] as String,
      origin: d['origin'] as String,
      destination: d['destination'] as String,
      operatorName: d['operatorName'] as String,
      departureTime: (d['departureTime'] as Timestamp).toDate(),
      arrivalTime: (d['arrivalTime'] as Timestamp).toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
        id, userId, tripId, passengerName, passengerPhone,
        paymentStatus, status, departureTime,
      ];
}
