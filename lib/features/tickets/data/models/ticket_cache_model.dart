import 'package:bookme_summative_project/features/booking/data/models/booking_model.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

/// Converts a [Ticket] to and from plain JSON for the on-device cache.
///
/// Firestore models use `Timestamp`, which cannot be JSON-encoded, so dates
/// are stored here as ISO-8601 strings instead.
class TicketCacheModel {
  const TicketCacheModel._();

  static Map<String, dynamic> toJson(Ticket ticket) {
    final booking = ticket.booking;
    final trip = ticket.trip;
    return {
      'tripStatus': ticket.tripStatus.name,
      'booking': {
        'id': booking.id,
        'userId': booking.userId,
        'reference': booking.reference,
        'tripId': booking.tripId,
        'seatNumber': booking.seatNumber,
        'status': booking.status.name,
        'holdExpiresAt': booking.holdExpiresAt.toIso8601String(),
        'totalAmount': booking.totalAmount,
        'currency': booking.currency,
        'createdAt': booking.createdAt.toIso8601String(),
        'passenger': booking.passenger == null
            ? null
            : BookingModel.passengerToMap(booking.passenger!),
        'paymentId': booking.paymentId,
      },
      'trip': {
        'tripId': trip.tripId,
        'operatorName': trip.operatorName,
        'fromCode': trip.fromCode,
        'fromStation': trip.fromStation,
        'toCode': trip.toCode,
        'toStation': trip.toStation,
        'departure': trip.departure.toIso8601String(),
        'arrival': trip.arrival.toIso8601String(),
        'durationLabel': trip.durationLabel,
        'baseFare': trip.baseFare,
        'taxes': trip.taxes,
        'serviceFee': trip.serviceFee,
        'currency': trip.currency,
      },
    };
  }

  static Ticket fromJson(Map<String, dynamic> json) {
    final b = Map<String, dynamic>.from(json['booking'] as Map);
    final t = Map<String, dynamic>.from(json['trip'] as Map);
    final passenger = b['passenger'];

    return Ticket(
      tripStatus: TripStatus.fromName(json['tripStatus'] as String?),
      booking: Booking(
        id: b['id'] as String,
        userId: b['userId'] as String,
        reference: b['reference'] as String,
        tripId: b['tripId'] as String,
        seatNumber: b['seatNumber'] as String,
        status: BookingStatus.fromName(b['status'] as String?),
        holdExpiresAt: DateTime.parse(b['holdExpiresAt'] as String),
        totalAmount: (b['totalAmount'] as num).toInt(),
        currency: b['currency'] as String,
        createdAt: DateTime.parse(b['createdAt'] as String),
        passenger: passenger is Map
            ? BookingModel.passengerFromMap(
                Map<String, dynamic>.from(passenger),
              )
            : null,
        paymentId: b['paymentId'] as String?,
      ),
      trip: TripSummary(
        tripId: t['tripId'] as String,
        operatorName: t['operatorName'] as String,
        fromCode: t['fromCode'] as String,
        fromStation: t['fromStation'] as String,
        toCode: t['toCode'] as String,
        toStation: t['toStation'] as String,
        departure: DateTime.parse(t['departure'] as String),
        arrival: DateTime.parse(t['arrival'] as String),
        durationLabel: t['durationLabel'] as String,
        baseFare: (t['baseFare'] as num).toInt(),
        taxes: (t['taxes'] as num).toInt(),
        serviceFee: (t['serviceFee'] as num).toInt(),
        currency: t['currency'] as String,
      ),
    );
  }
}
