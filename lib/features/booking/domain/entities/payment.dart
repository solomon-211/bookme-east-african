import 'package:equatable/equatable.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/payment_method.dart';

enum PaymentStatus {
  /// Document created, provider not contacted yet.
  pending,

  /// The PIN prompt (or payment link) has been sent; waiting for the payer.
  awaitingApproval,

  /// The provider confirmed the money was taken.
  successful,

  /// Declined, timed out, or the provider returned an error.
  failed;

  bool get isFinal => this == successful || this == failed;

  static PaymentStatus fromName(String? name) => PaymentStatus.values
      .firstWhere((s) => s.name == name, orElse: () => PaymentStatus.pending);
}

/// Where the money sits. BookMe never pays the operator until boarding is
/// verified; the Trust & Account feature shows this as the escrow tracker.
enum EscrowStatus {
  none,
  held,
  released,
  refunded;

  static EscrowStatus fromName(String? name) => EscrowStatus.values.firstWhere(
    (s) => s.name == name,
    orElse: () => EscrowStatus.none,
  );
}

class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.method,
    required this.payerPhone,
    required this.amount,
    required this.currency,
    required this.status,
    required this.escrowStatus,
    required this.createdAt,
    this.paidByOther = false,
    this.providerRef,
    this.failureReason,
    this.paidAt,
  });

  final String id;
  final String bookingId;

  /// Owner of the booking (not necessarily the payer).
  final String userId;
  final PaymentMethod method;

  /// Phone that receives the PIN prompt. Empty for card payments.
  final String payerPhone;
  final int amount;
  final String currency;
  final PaymentStatus status;
  final EscrowStatus escrowStatus;
  final DateTime createdAt;

  /// True when the payment came from a "someone else is paying" request.
  final bool paidByOther;
  final String? providerRef;
  final String? failureReason;
  final DateTime? paidAt;

  /// `•••• 4412` style display, so we never show a full number on screen.
  String get maskedPhone {
    if (payerPhone.length < 4) return '';
    return '•••• ${payerPhone.substring(payerPhone.length - 4)}';
  }

  Payment copyWith({
    PaymentStatus? status,
    EscrowStatus? escrowStatus,
    String? providerRef,
    String? failureReason,
    DateTime? paidAt,
  }) {
    return Payment(
      id: id,
      bookingId: bookingId,
      userId: userId,
      method: method,
      payerPhone: payerPhone,
      amount: amount,
      currency: currency,
      status: status ?? this.status,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      createdAt: createdAt,
      paidByOther: paidByOther,
      providerRef: providerRef ?? this.providerRef,
      failureReason: failureReason ?? this.failureReason,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bookingId,
    userId,
    method,
    payerPhone,
    amount,
    currency,
    status,
    escrowStatus,
    createdAt,
    paidByOther,
    providerRef,
    failureReason,
    paidAt,
  ];
}
