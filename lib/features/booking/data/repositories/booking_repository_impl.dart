import 'dart:async';

import 'package:bookme_summative_project/features/booking/data/datasources/booking_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/firebase_error_mapper.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/passenger.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/booking/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl(this._source);

  final BookingDataSource _source;

  @override
  Future<Booking> holdSeat(TripSummary trip) async {
    try {
      return await _source.holdSeat(trip);
    } catch (e) {
      throw mapFirebaseError(
        e,
        fallback: 'We couldn\'t hold a seat just now. Please try again.',
      );
    }
  }

  @override
  Stream<Booking> watchBooking(String bookingId) =>
      _source.watchBooking(bookingId);

  @override
  Future<void> savePassenger({
    required String bookingId,
    required Passenger passenger,
  }) async {
    try {
      await _source.savePassenger(bookingId, passenger);
    } catch (e) {
      throw mapFirebaseError(
        e,
        fallback: 'We couldn\'t save the passenger details. Please try again.',
      );
    }
  }

  @override
  Future<void> releaseHold(Booking booking) async {
    try {
      await _source.releaseHold(booking);
    } catch (_) {
      // Releasing is best effort: an expired hold can be re-claimed by the
      // next traveller anyway (see BookingFirestoreDataSource.holdSeat).
    }
  }
}
