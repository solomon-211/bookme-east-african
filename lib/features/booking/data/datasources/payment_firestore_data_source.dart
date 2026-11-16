import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/booking/data/datasources/payment_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/models/payment_model.dart';
import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';

/// Firestore access for the `payments` collection.
class PaymentFirestoreDataSource implements PaymentDataSource {
  PaymentFirestoreDataSource({required FirebaseFirestore firestore})
    : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _payments =>
      _db.collection('payments');

  DocumentReference<Map<String, dynamic>> _booking(String id) =>
      _db.collection('bookings').doc(id);

  @override
  String newPaymentId() => _payments.doc().id;

  @override
  Future<void> create(Payment payment) async {
    final batch = _db.batch()
      ..set(_payments.doc(payment.id), PaymentModel.toMap(payment))
      ..update(_booking(payment.bookingId), {
        'paymentId': payment.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }

  @override
  Future<void> markAwaitingApproval(String paymentId) {
    return _payments.doc(paymentId).update({
      'status': PaymentStatus.awaitingApproval.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Records a successful payment. In one transaction:
  /// 1. the payment becomes `successful` with money `held` in escrow,
  /// 2. the booking becomes `paid`,
  /// 3. the seat becomes `booked` so nobody else can hold it.
  ///
  /// Nothing is written if the booking is no longer a `held` booking or the
  /// seat now belongs to someone else (the hold expired while the payer was
  /// approving). Without this check a late approval could book a seat that
  /// another traveller is already holding.
  @override
  Future<bool> complete({
    required Payment payment,
    required Booking booking,
    required String providerRef,
  }) {
    final seatRef = _db
        .collection('trips')
        .doc(booking.tripId)
        .collection('seats')
        .doc(booking.seatNumber);
    final bookingRef = _booking(booking.id);

    return _db.runTransaction((tx) async {
      final bookingSnap = await tx.get(bookingRef);
      final seatSnap = await tx.get(seatRef);

      final stillHeld =
          bookingSnap.data()?['status'] == BookingStatus.held.name;
      final seatStillOurs =
          seatSnap.data()?['bookingId'] == booking.id &&
          seatSnap.data()?['status'] == 'held';
      if (!stillHeld || !seatStillOurs) return false;

      tx
        ..update(_payments.doc(payment.id), {
          'status': PaymentStatus.successful.name,
          'escrowStatus': EscrowStatus.held.name,
          'providerRef': providerRef,
          'paidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        ..update(bookingRef, {
          'status': BookingStatus.paid.name,
          'paymentId': payment.id,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        ..update(seatRef, {'status': 'booked', 'holdExpiresAt': null});
      return true;
    });
  }

  @override
  Future<void> fail(String paymentId, String reason) {
    return _payments.doc(paymentId).update({
      'status': PaymentStatus.failed.name,
      'failureReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<Payment> watch(String paymentId) {
    return _payments
        .doc(paymentId)
        .snapshots()
        .where((snap) => snap.exists && snap.data() != null)
        .map((snap) => PaymentModel.fromMap(snap.id, snap.data()!));
  }

  @override
  Future<Payment> get(String paymentId) async {
    // Skip the local cache so "Check Payment Status" really asks the server.
    final snap = await _payments
        .doc(paymentId)
        .get(const GetOptions(source: Source.server));
    final data = snap.data();
    if (data == null) {
      throw const BookingFailure(
        'We couldn\'t find this payment any more. Please start again.',
      );
    }
    return PaymentModel.fromMap(snap.id, data);
  }
}
