import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';

/// Storage for payments.
///
/// [PaymentFirestoreDataSource] is the real implementation;
/// [InMemoryPaymentDataSource] lets the app and tests run without Firebase.
abstract interface class PaymentDataSource {
  /// A fresh id, so the entity can be built before it is saved.
  String newPaymentId();

  /// Saves the payment and links it to its booking.
  Future<void> create(Payment payment);

  Future<void> markAwaitingApproval(String paymentId);

  /// Records a successful payment: payment `successful` with money `held`
  /// in escrow, booking `paid`, seat `booked`, all in one atomic step.
  ///
  /// Returns `false` (and changes nothing) when the seat hold is no longer
  /// valid, e.g. it expired and another traveller took the seat while the
  /// payer was approving. The caller must then fail the payment.
  Future<bool> complete({
    required Payment payment,
    required Booking booking,
    required String providerRef,
  });

  Future<void> fail(String paymentId, String reason);

  Stream<Payment> watch(String paymentId);

  /// Reads straight from the server (skips any local cache).
  Future<Payment> get(String paymentId);
}
