import 'package:equatable/equatable.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/passenger.dart';

/// How long a seat stays reserved while the traveller pays for it.
const Duration kSeatHoldDuration = Duration(minutes: 10);

/// How long a "someone else is paying" request keeps the seat reserved.
const Duration kPaymentRequestDuration = Duration(minutes: 30);

enum BookingStatus {
  /// Seat is reserved for a limited time and waiting for payment.
  held,

  /// Payment succeeded; money is in escrow and the seat is guaranteed.
  paid,

  /// The hold ran out before payment, so the seat was released.
  expired,

  /// Cancelled by the traveller or the operator (handled by Tickets & Trips).
  cancelled;

  static BookingStatus fromName(String? name) => BookingStatus.values
      .firstWhere((s) => s.name == name, orElse: () => BookingStatus.expired);
}

/// One seat on one trip for one passenger.
///
/// A booking starts life as a seat hold (status [BookingStatus.held]) and
/// becomes [BookingStatus.paid] once the payment clears. Keeping the hold
/// and the booking in one document means there is no duplicated data to
/// keep in sync.
class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.userId,
    required this.reference,
    required this.tripId,
    required this.seatNumber,
    required this.status,
    required this.holdExpiresAt,
    required this.totalAmount,
    required this.currency,
    required this.createdAt,
    this.passenger,
    this.paymentId,
  });

  final String id;

  /// Firebase Auth uid of the account that owns the booking.
  final String userId;

  /// Human-friendly code printed on the ticket, e.g. `BME-7K2Q-4C`.
  final String reference;
  final String tripId;
  final String seatNumber;
  final BookingStatus status;
  final DateTime holdExpiresAt;
  final int totalAmount;
  final String currency;
  final DateTime createdAt;
  final Passenger? passenger;
  final String? paymentId;

  /// Time left on the hold, never negative.
  Duration remainingHold(DateTime now) {
    final left = holdExpiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isHoldActive(DateTime now) =>
      status == BookingStatus.held && now.isBefore(holdExpiresAt);

  Booking copyWith({
    BookingStatus? status,
    DateTime? holdExpiresAt,
    Passenger? passenger,
    String? paymentId,
  }) {
    return Booking(
      id: id,
      userId: userId,
      reference: reference,
      tripId: tripId,
      seatNumber: seatNumber,
      status: status ?? this.status,
      holdExpiresAt: holdExpiresAt ?? this.holdExpiresAt,
      totalAmount: totalAmount,
      currency: currency,
      createdAt: createdAt,
      passenger: passenger ?? this.passenger,
      paymentId: paymentId ?? this.paymentId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    reference,
    tripId,
    seatNumber,
    status,
    holdExpiresAt,
    totalAmount,
    currency,
    createdAt,
    passenger,
    paymentId,
  ];
}
