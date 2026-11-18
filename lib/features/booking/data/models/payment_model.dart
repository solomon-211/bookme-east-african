import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment_method.dart';

/// Converts between [Payment] and the `payments/{paymentId}` document.
class PaymentModel {
  const PaymentModel._();

  static Map<String, dynamic> toMap(Payment payment) {
    return {
      'bookingId': payment.bookingId,
      'userId': payment.userId,
      'method': payment.method.name,
      'payerPhone': payment.payerPhone,
      'amount': payment.amount,
      'currency': payment.currency,
      'status': payment.status.name,
      'escrowStatus': payment.escrowStatus.name,
      'paidByOther': payment.paidByOther,
      'providerRef': payment.providerRef,
      'failureReason': payment.failureReason,
      'createdAt': Timestamp.fromDate(payment.createdAt),
      'paidAt': payment.paidAt == null
          ? null
          : Timestamp.fromDate(payment.paidAt!),
    };
  }

  static Payment fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      bookingId: map['bookingId'] as String,
      userId: map['userId'] as String,
      method: PaymentMethod.fromName(map['method'] as String?),
      payerPhone: map['payerPhone'] as String? ?? '',
      amount: (map['amount'] as num).toInt(),
      currency: map['currency'] as String? ?? 'RWF',
      status: PaymentStatus.fromName(map['status'] as String?),
      escrowStatus: EscrowStatus.fromName(map['escrowStatus'] as String?),
      paidByOther: map['paidByOther'] as bool? ?? false,
      providerRef: map['providerRef'] as String?,
      failureReason: map['failureReason'] as String?,
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      paidAt: _readDate(map['paidAt']),
    );
  }

  static DateTime? _readDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}
