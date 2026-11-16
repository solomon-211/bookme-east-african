import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment_method.dart';
import 'package:bookme_summative_project/features/booking/domain/repositories/payment_repository.dart';
import 'package:bookme_summative_project/features/booking/domain/validators/passenger_validators.dart';

enum PaymentFlowStatus {
  /// Choosing a method; nothing sent yet.
  idle,

  /// Creating the payment and sending the prompt.
  submitting,

  /// Prompt or link sent; waiting for the payer to approve.
  awaitingApproval,
  successful,
  failed,
}

class PaymentState extends Equatable {
  const PaymentState({
    this.method = PaymentMethod.mtnMomo,
    this.phone = '',
    this.status = PaymentFlowStatus.idle,
    this.payment,
    this.isRequest = false,
    this.isChecking = false,
    this.message,
  });

  final PaymentMethod method;

  /// Number that receives the prompt (restored from SharedPreferences).
  final String phone;
  final PaymentFlowStatus status;
  final Payment? payment;

  /// True when someone else is paying through a link.
  final bool isRequest;

  /// True while "Check Payment Status" is waiting for the server.
  final bool isChecking;

  /// Polite error to show in a snack bar.
  final String? message;

  bool get isBusy =>
      status == PaymentFlowStatus.submitting ||
      status == PaymentFlowStatus.awaitingApproval;

  PaymentState copyWith({
    PaymentMethod? method,
    String? phone,
    PaymentFlowStatus? status,
    Payment? payment,
    bool clearPayment = false,
    bool? isRequest,
    bool? isChecking,
    String? message,
    bool clearMessage = false,
  }) {
    return PaymentState(
      method: method ?? this.method,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      payment: clearPayment ? null : (payment ?? this.payment),
      isRequest: isRequest ?? this.isRequest,
      isChecking: isChecking ?? this.isChecking,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
    method,
    phone,
    status,
    payment,
    isRequest,
    isChecking,
    message,
  ];
}

/// Runs the payment from "Pay for your seat" to "Payment received".
class PaymentCubit extends Cubit<PaymentState> {
  PaymentCubit({required this._repository}) : super(const PaymentState());

  final PaymentRepository _repository;
  StreamSubscription<Payment>? _paymentSub;

  /// Restores the last method and phone used on this device.
  Future<void> loadPreferences({String fallbackPhone = ''}) async {
    PaymentPreference? saved;
    try {
      saved = await _repository.loadLastPreference();
    } catch (_) {
      saved = null;
    }
    if (isClosed) return;
    final savedPhone = saved?.phone ?? '';
    emit(
      state.copyWith(
        method: saved?.method,
        phone: savedPhone.isNotEmpty ? savedPhone : fallbackPhone,
      ),
    );
  }

  void selectMethod(PaymentMethod method) {
    if (state.isBusy) return;
    emit(state.copyWith(method: method, clearMessage: true));
  }

  /// Pays with the selected method. Ignored while a payment is already in
  /// flight, so a double tap can never create two charges.
  Future<void> pay({required Booking booking, required String phone}) async {
    if (state.isBusy) return;
    final normalized = PassengerValidators.normalizePhone(phone);
    emit(
      state.copyWith(
        status: PaymentFlowStatus.submitting,
        phone: normalized,
        isRequest: false,
        clearPayment: true,
        clearMessage: true,
      ),
    );
    try {
      final payment = await _repository.startPayment(
        booking: booking,
        method: state.method,
        payerPhone: normalized,
      );
      unawaited(_savePreference(state.method, normalized));
      _follow(payment);
    } on BookingFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PaymentFlowStatus.idle,
            message: failure.message,
          ),
        );
      }
    }
  }

  /// "Someone else is paying": sends a link and waits for them.
  Future<void> requestFromSomeoneElse({
    required Booking booking,
    required String payerPhone,
  }) async {
    if (state.isBusy) return;
    emit(
      state.copyWith(
        status: PaymentFlowStatus.submitting,
        isRequest: true,
        clearPayment: true,
        clearMessage: true,
      ),
    );
    try {
      final payment = await _repository.requestPaymentFromOther(
        booking: booking,
        payerPhone: PassengerValidators.normalizePhone(payerPhone),
      );
      _follow(payment);
    } on BookingFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: PaymentFlowStatus.idle,
            message: failure.message,
          ),
        );
      }
    }
  }

  /// "Check Payment Status": asks the server directly, useful when the live
  /// listener was interrupted by a weak connection.
  Future<void> checkStatus() async {
    final payment = state.payment;
    if (payment == null || state.isChecking) return;
    emit(state.copyWith(isChecking: true, clearMessage: true));
    try {
      final fresh = await _repository.refreshPayment(payment.id);
      _apply(fresh);
      if (!isClosed && fresh.status == PaymentStatus.awaitingApproval) {
        emit(
          state.copyWith(message: 'Still waiting for approval on the phone.'),
        );
      }
    } on BookingFailure catch (failure) {
      if (!isClosed) emit(state.copyWith(message: failure.message));
    } finally {
      if (!isClosed) emit(state.copyWith(isChecking: false));
    }
  }

  /// "Change Payment Method": abandons the current prompt safely.
  Future<void> changeMethod() async {
    final payment = state.payment;
    await _paymentSub?.cancel();
    _paymentSub = null;
    if (payment != null && !payment.status.isFinal) {
      await _repository.cancelPayment(payment.id);
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          status: PaymentFlowStatus.idle,
          isRequest: false,
          clearPayment: true,
          clearMessage: true,
        ),
      );
    }
  }

  void _follow(Payment payment) {
    if (isClosed) return;
    _apply(payment);
    _paymentSub?.cancel();
    _paymentSub = _repository
        .watchPayment(payment.id)
        .listen(_apply, onError: (Object _) {});
  }

  void _apply(Payment payment) {
    if (isClosed) return;
    switch (payment.status) {
      case PaymentStatus.pending:
      case PaymentStatus.awaitingApproval:
        emit(
          state.copyWith(
            status: PaymentFlowStatus.awaitingApproval,
            payment: payment,
          ),
        );
      case PaymentStatus.successful:
        _paymentSub?.cancel();
        emit(
          state.copyWith(
            status: PaymentFlowStatus.successful,
            payment: payment,
          ),
        );
      case PaymentStatus.failed:
        _paymentSub?.cancel();
        emit(
          state.copyWith(
            status: PaymentFlowStatus.failed,
            payment: payment,
            message:
                payment.failureReason ??
                'The payment didn\'t go through. No money was taken.',
          ),
        );
    }
  }

  Future<void> _savePreference(PaymentMethod method, String phone) async {
    try {
      await _repository.saveLastPreference(method, phone);
    } catch (_) {
      // A preference that fails to save should never block a payment.
    }
  }

  @override
  Future<void> close() async {
    // Leaving the flow (back button or expired hold) while a prompt is still
    // pending abandons that payment, so a late approval is never charged.
    final payment = state.payment;
    if (payment != null && !payment.status.isFinal) {
      unawaited(_repository.cancelPayment(payment.id));
    }
    await _paymentSub?.cancel();
    return super.close();
  }
}
