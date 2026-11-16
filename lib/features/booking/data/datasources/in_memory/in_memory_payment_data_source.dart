import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_booking_store.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/payment_data_source.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';

/// Same behaviour as [PaymentDataSource]'s Firestore version, without a
/// server.
class InMemoryPaymentDataSource implements PaymentDataSource {
  InMemoryPaymentDataSource(this._store);

  final InMemoryBookingStore _store;

  @override
  String newPaymentId() => _store.newId('payment');

  @override
  Future<void> create(Payment payment) async {
    await _store.simulateNetwork();
    final booking = _store.requireBooking(payment.bookingId);
    _store
      ..putPayment(payment)
      ..putBooking(booking.copyWith(paymentId: payment.id));
  }

  @override
  Future<void> markAwaitingApproval(String paymentId) async {
    await _store.simulateNetwork();
    final payment = _store.requirePayment(paymentId);
    _store.putPayment(payment.copyWith(status: PaymentStatus.awaitingApproval));
  }

  @override
  Future<bool> complete({
    required Payment payment,
    required Booking booking,
    required String providerRef,
  }) async {
    await _store.simulateNetwork();
    final current = _store.booking(booking.id);
    final seat = _store.seat(booking.tripId, booking.seatNumber);
    if (current == null ||
        current.status != BookingStatus.held ||
        seat == null ||
        !seat.isHeldBy(booking.id)) {
      return false;
    }

    seat
      ..status = 'booked'
      ..holdExpiresAt = null;
    _store
      ..putPayment(
        _store
            .requirePayment(payment.id)
            .copyWith(
              status: PaymentStatus.successful,
              escrowStatus: EscrowStatus.held,
              providerRef: providerRef,
              paidAt: _store.now(),
            ),
      )
      ..putBooking(
        current.copyWith(status: BookingStatus.paid, paymentId: payment.id),
      );
    return true;
  }

  @override
  Future<void> fail(String paymentId, String reason) async {
    await _store.simulateNetwork();
    final payment = _store.requirePayment(paymentId);
    _store.putPayment(
      payment.copyWith(status: PaymentStatus.failed, failureReason: reason),
    );
  }

  @override
  Stream<Payment> watch(String paymentId) => _store.watchPayment(paymentId);

  @override
  Future<Payment> get(String paymentId) async {
    await _store.simulateNetwork();
    return _store.requirePayment(paymentId);
  }
}
