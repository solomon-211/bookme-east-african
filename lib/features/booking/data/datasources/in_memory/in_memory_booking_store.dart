import 'dart:async';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';

/// One seat document, `trips/{tripId}/seats/{seatNumber}`, kept in memory.
class InMemorySeat {
  String status = 'available';
  String? bookingId;
  DateTime? holdExpiresAt;

  /// Free, or held by a hold that has already run out.
  bool isFree(DateTime now) =>
      status == 'available' ||
      (status == 'held' && (holdExpiresAt?.isBefore(now) ?? true));

  bool isHeldBy(String bookingId) =>
      status == 'held' && this.bookingId == bookingId;

  void release() {
    status = 'available';
    bookingId = null;
    holdExpiresAt = null;
  }
}

/// A tiny stand-in for Firestore used when Firebase is not configured and in
/// tests. It keeps seats, bookings and payments in memory and pushes every
/// change to live listeners, like `snapshots()` does.
///
/// Data is lost when the app restarts.
class InMemoryBookingStore {
  InMemoryBookingStore({
    this.userId = 'demo-user',
    this.latency = Duration.zero,
    DateTime Function()? clock,
  }) : now = clock ?? DateTime.now;

  /// Plays the role of the Firebase Auth uid.
  final String userId;

  /// Fake network delay added to every read and write, so loading states
  /// can be seen in the demo.
  final Duration latency;
  final DateTime Function() now;

  final Map<String, Map<String, InMemorySeat>> _seats = {};
  final Map<String, Booking> _bookings = {};
  final Map<String, Payment> _payments = {};

  final StreamController<Booking> _bookingChanges =
      StreamController<Booking>.broadcast();
  final StreamController<Payment> _paymentChanges =
      StreamController<Payment>.broadcast();

  int _counter = 0;

  String newId(String prefix) => '$prefix-${++_counter}';

  Future<void> simulateNetwork() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  /// Adds [seatNumbers] to [tripId] as free seats. Seats that already exist
  /// are reset to free, like the "Create demo seats" button does in
  /// Firestore.
  void resetSeats(String tripId, Iterable<String> seatNumbers) {
    final trip = _seats.putIfAbsent(tripId, () => {});
    for (final number in seatNumbers) {
      trip[number] = InMemorySeat();
    }
  }

  Map<String, InMemorySeat> seatsOf(String tripId) => _seats[tripId] ?? {};

  InMemorySeat? seat(String tripId, String seatNumber) =>
      _seats[tripId]?[seatNumber];

  Booking? booking(String id) => _bookings[id];

  Payment? payment(String id) => _payments[id];

  Booking requireBooking(String id) {
    final booking = _bookings[id];
    if (booking == null) {
      throw const BookingFailure(
        'We couldn\'t find this booking any more. Please start again.',
      );
    }
    return booking;
  }

  Payment requirePayment(String id) {
    final payment = _payments[id];
    if (payment == null) {
      throw const BookingFailure(
        'We couldn\'t find this payment any more. Please start again.',
      );
    }
    return payment;
  }

  void putBooking(Booking booking) {
    _bookings[booking.id] = booking;
    _bookingChanges.add(booking);
  }

  void putPayment(Payment payment) {
    _payments[payment.id] = payment;
    _paymentChanges.add(payment);
  }

  /// Emits the current booking first, then every change, like Firestore.
  Stream<Booking> watchBooking(String id) =>
      _watch(() => _bookings[id], _bookingChanges.stream, (b) => b.id == id);

  Stream<Payment> watchPayment(String id) =>
      _watch(() => _payments[id], _paymentChanges.stream, (p) => p.id == id);

  Stream<T> _watch<T>(
    T? Function() current,
    Stream<T> changes,
    bool Function(T) matches,
  ) {
    late final StreamController<T> controller;
    StreamSubscription<T>? sub;
    controller = StreamController<T>(
      onListen: () {
        final value = current();
        if (value != null) controller.add(value);
        sub = changes.where(matches).listen(controller.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }
}
