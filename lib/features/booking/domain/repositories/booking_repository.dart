import 'dart:async';

import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/passenger.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';

/// Seat holds and bookings. Implemented in the data layer with Firestore.
abstract class BookingRepository {
  /// Atomically reserves the next free seat on [trip] for
  /// [kSeatHoldDuration] and creates a booking in `held` status.
  ///
  /// Throws a `BookingFailure` when the bus is full.
  Future<Booking> holdSeat(TripSummary trip);

  /// Live updates for one booking (status changes, extended holds).
  Stream<Booking> watchBooking(String bookingId);

  /// Attaches the traveller's details to a held booking.
  Future<void> savePassenger({
    required String bookingId,
    required Passenger passenger,
  });

  /// Gives the seat back when the hold runs out or the traveller leaves.
  Future<void> releaseHold(Booking booking);
}
