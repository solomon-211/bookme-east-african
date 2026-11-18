import 'dart:async';

import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment_method.dart';

/// The last method and phone used, restored the next time the traveller pays.
class PaymentPreference {
  const PaymentPreference({required this.method, required this.phone});

  final PaymentMethod method;
  final String phone;
}

abstract class PaymentRepository {
  /// Creates a payment for [booking] and sends the PIN prompt to
  /// [payerPhone]. Returns as soon as the prompt is sent; follow the result
  /// with [watchPayment].
  Future<Payment> startPayment({
    required Booking booking,
    required PaymentMethod method,
    required String payerPhone,
  });

  /// Sends a secure payment link to someone else and keeps the seat
  /// reserved for [kPaymentRequestDuration] while they pay.
  Future<Payment> requestPaymentFromOther({
    required Booking booking,
    required String payerPhone,
  });

  Stream<Payment> watchPayment(String paymentId);

  /// Called when the traveller switches method while a prompt is pending.
  /// Guarantees the abandoned prompt can never also be charged.
  Future<void> cancelPayment(String paymentId);

  /// One-off read used by the "Check Payment Status" button.
  Future<Payment> refreshPayment(String paymentId);

  Future<PaymentPreference?> loadLastPreference();

  Future<void> saveLastPreference(PaymentMethod method, String phone);
}
