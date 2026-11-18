import 'dart:async';

import 'package:bookme_summative_project/features/booking/data/datasources/booking_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/payment_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/firebase_error_mapper.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/payment_preferences_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/gateways/mobile_money_gateway.dart';
import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment_method.dart';
import 'package:bookme_summative_project/features/booking/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({
    required PaymentDataSource paymentSource,
    required BookingDataSource bookingSource,
    required this._gateway,
    required this._preferences,
    DateTime Function()? clock,
  }) : _payments = paymentSource,
       _bookings = bookingSource,
       _now = clock ?? DateTime.now;

  final PaymentDataSource _payments;
  final BookingDataSource _bookings;
  final MobileMoneyGateway _gateway;
  final PaymentPreferencesDataSource _preferences;
  final DateTime Function() _now;

  /// Payments the traveller abandoned. A late "approved" from the provider
  /// for one of these is ignored, so nobody is ever charged twice.
  final Set<String> _cancelled = {};

  @override
  Future<Payment> startPayment({
    required Booking booking,
    required PaymentMethod method,
    required String payerPhone,
  }) {
    return _createAndSend(
      booking: booking,
      method: method,
      payerPhone: payerPhone,
      paidByOther: false,
    );
  }

  @override
  Future<Payment> requestPaymentFromOther({
    required Booking booking,
    required String payerPhone,
  }) async {
    _ensureHoldActive(booking);
    try {
      final extended = await _bookings.extendHold(
        booking,
        _now().add(kPaymentRequestDuration),
      );
      // In the mock the payer approves with MTN MoMo. A real link would let
      // them choose any method on the web payment page.
      return await _createAndSend(
        booking: extended,
        method: PaymentMethod.mtnMomo,
        payerPhone: payerPhone,
        paidByOther: true,
      );
    } catch (e) {
      throw mapFirebaseError(
        e,
        fallback: 'We couldn\'t send the payment request. Please try again.',
      );
    }
  }

  Future<Payment> _createAndSend({
    required Booking booking,
    required PaymentMethod method,
    required String payerPhone,
    required bool paidByOther,
  }) async {
    _ensureHoldActive(booking);
    try {
      final payment = Payment(
        id: _payments.newPaymentId(),
        bookingId: booking.id,
        userId: booking.userId,
        method: method,
        payerPhone: method.needsPhone ? payerPhone : '',
        amount: booking.totalAmount,
        currency: booking.currency,
        status: PaymentStatus.pending,
        escrowStatus: EscrowStatus.none,
        createdAt: _now(),
        paidByOther: paidByOther,
      );
      await _payments.create(payment);
      await _payments.markAwaitingApproval(payment.id);

      final sent = payment.copyWith(status: PaymentStatus.awaitingApproval);
      // Do not await: the UI follows the result through watchPayment.
      unawaited(_settle(sent, booking));
      return sent;
    } catch (e) {
      throw mapFirebaseError(
        e,
        fallback: 'We couldn\'t start the payment. You have not been charged.',
      );
    }
  }

  /// Waits for the provider and writes the outcome to Firestore. In
  /// production this would be a Cloud Function receiving a webhook.
  Future<void> _settle(Payment payment, Booking booking) async {
    try {
      final result = await _gateway.requestToPay(
        paymentId: payment.id,
        method: payment.method,
        phone: payment.payerPhone,
        amount: payment.amount,
        currency: payment.currency,
      );
      if (_cancelled.contains(payment.id)) return;
      if (result.approved) {
        final completed = await _payments.complete(
          payment: payment,
          booking: booking,
          providerRef: result.providerRef!,
        );
        if (!completed) {
          // A real integration would refund through the provider here.
          await _payments.fail(
            payment.id,
            'Your seat hold ended before the payment was approved, so the '
            'payment was cancelled. No money was taken.',
          );
        }
      } else {
        await _payments.fail(payment.id, result.reason!);
      }
    } catch (_) {
      try {
        await _payments.fail(
          payment.id,
          'We couldn\'t reach the payment provider. No money was taken.',
        );
      } catch (_) {
        // Offline: Firestore keeps the write queued and sends it later.
      }
    }
  }

  void _ensureHoldActive(Booking booking) {
    if (!booking.isHoldActive(_now())) {
      throw const BookingFailure(
        'Your seat hold has expired. Please choose the trip again.',
      );
    }
  }

  @override
  Stream<Payment> watchPayment(String paymentId) => _payments.watch(paymentId);

  @override
  Future<void> cancelPayment(String paymentId) async {
    _cancelled.add(paymentId);
    try {
      await _payments.fail(
        paymentId,
        'Cancelled because you chose another payment method.',
      );
    } catch (_) {
      // Already recorded locally; the provider result will be ignored.
    }
  }

  @override
  Future<Payment> refreshPayment(String paymentId) async {
    try {
      return await _payments.get(paymentId);
    } catch (e) {
      throw mapFirebaseError(
        e,
        fallback: 'We couldn\'t check the payment status. Please try again.',
      );
    }
  }

  @override
  Future<PaymentPreference?> loadLastPreference() async => _preferences.load();

  @override
  Future<void> saveLastPreference(PaymentMethod method, String phone) =>
      _preferences.save(method, phone);
}
