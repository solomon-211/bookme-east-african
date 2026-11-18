import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/passenger.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

import 'test_trip.dart';

/// A paid Kigali → Kampala ticket for `demo-user`, on [testTrip].
Ticket testTicket({
  String id = 'booking-1',
  BookingStatus status = BookingStatus.paid,
  String seat = '4C',
}) => Ticket(
  booking: Booking(
    id: id,
    userId: 'demo-user',
    reference: 'BME-7K2Q-4C',
    tripId: testTrip.tripId,
    seatNumber: seat,
    status: status,
    holdExpiresAt: DateTime(2026, 11, 16, 12, 10),
    totalAmount: 18500,
    currency: 'RWF',
    createdAt: DateTime(2026, 11, 16, 12),
    passenger: const Passenger(
      fullName: 'Moses Mugisha',
      phone: '+250781234412',
      idNumber: '1199080012345678',
      nationality: 'Rwanda',
    ),
    paymentId: 'payment-1',
  ),
  trip: testTrip,
);
