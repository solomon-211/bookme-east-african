import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/passenger.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';

/// Storage for seat holds and bookings.
///
/// [BookingFirestoreDataSource] is the real implementation;
/// [InMemoryBookingDataSource] lets the app and tests run without Firebase.
abstract interface class BookingDataSource {
  /// Atomically reserves a free (or expired) seat and creates a `held`
  /// booking. Throws a `BookingFailure` when no seat is left.
  Future<Booking> holdSeat(TripSummary trip);

  Stream<Booking> watchBooking(String bookingId);

  Future<void> savePassenger(String bookingId, Passenger passenger);

  /// Keeps the seat reserved until [until] (used while someone else pays).
  Future<Booking> extendHold(Booking booking, DateTime until);

  /// Frees the seat and marks the booking expired, but only while the
  /// booking is still an unpaid hold.
  Future<void> releaseHold(Booking booking);
}
