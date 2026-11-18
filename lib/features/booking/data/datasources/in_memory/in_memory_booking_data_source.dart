import 'dart:math';

import 'package:bookme_summative_project/features/booking/data/datasources/booking_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_booking_store.dart';
import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/passenger.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/booking/domain/utils/booking_reference.dart';

/// Same behaviour as [BookingDataSource]'s Firestore version, without a
/// server. Every method runs synchronously after the fake latency, so each
/// one is atomic the same way a Firestore transaction is.
class InMemoryBookingDataSource implements BookingDataSource {
  // ignore: prefer_initializing_formals
  InMemoryBookingDataSource(this._store, {Random? random}) : _random = random;

  final InMemoryBookingStore _store;
  final Random? _random;

  @override
  Future<Booking> holdSeat(TripSummary trip) async {
    await _store.simulateNetwork();
    final now = _store.now();

    final free = _store
        .seatsOf(trip.tripId)
        .entries
        .where((entry) => entry.value.isFree(now))
        .firstOrNull;
    if (free == null) {
      throw const BookingFailure(
        'This bus is fully booked. Join the waitlist and we\'ll alert you '
        'if a seat opens.',
      );
    }

    final seatNumber = free.key;
    final booking = Booking(
      id: _store.newId('booking'),
      userId: _store.userId,
      reference: generateBookingReference(seatNumber, random: _random),
      tripId: trip.tripId,
      seatNumber: seatNumber,
      status: BookingStatus.held,
      holdExpiresAt: now.add(kSeatHoldDuration),
      totalAmount: trip.total,
      currency: trip.currency,
      createdAt: now,
    );
    free.value
      ..status = 'held'
      ..bookingId = booking.id
      ..holdExpiresAt = booking.holdExpiresAt;
    _store.putBooking(booking);
    return booking;
  }

  @override
  Stream<Booking> watchBooking(String bookingId) =>
      _store.watchBooking(bookingId);

  @override
  Future<void> savePassenger(String bookingId, Passenger passenger) async {
    await _store.simulateNetwork();
    final booking = _store.requireBooking(bookingId);
    _store.putBooking(booking.copyWith(passenger: passenger));
  }

  @override
  Future<Booking> extendHold(Booking booking, DateTime until) async {
    await _store.simulateNetwork();
    final current = _store.requireBooking(booking.id);
    final seat = _store.seat(booking.tripId, booking.seatNumber);
    if (seat != null && seat.isHeldBy(booking.id)) seat.holdExpiresAt = until;
    final updated = current.copyWith(holdExpiresAt: until);
    _store.putBooking(updated);
    return updated;
  }

  @override
  Future<void> releaseHold(Booking booking) async {
    await _store.simulateNetwork();
    final current = _store.booking(booking.id);
    if (current == null || current.status != BookingStatus.held) return;

    final seat = _store.seat(booking.tripId, booking.seatNumber);
    if (seat != null && seat.isHeldBy(booking.id)) seat.release();
    _store.putBooking(current.copyWith(status: BookingStatus.expired));
  }
}
