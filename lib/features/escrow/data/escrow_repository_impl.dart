import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/escrow_record.dart';
import '../domain/escrow_repository.dart';

// Builds the escrow view from documents other features write:
//   payments/{id}  - Booking & Payment (escrowStatus, amount, method)
//   bookings/{id}  - Booking & Payment (reference, seat, status)
//   trips/{id}     - Search (operator name)
// We only read here; nothing on this screen changes data.
class EscrowRepositoryImpl implements EscrowRepository {
  EscrowRepositoryImpl({
    required FirebaseFirestore firestore,
    required String? Function() currentUserId,
  }) : _db = firestore,
       _currentUserId = currentUserId; // ignore: prefer_initializing_formals

  final FirebaseFirestore _db;
  final String? Function() _currentUserId;

  static const _methodLabels = {
    'mtnMomo': 'MTN MoMo',
    'mpesa': 'M-Pesa',
    'airtelMoney': 'Airtel Money',
    'card': 'card',
  };

  @override
  Stream<EscrowRecord?> watchEscrow(String bookingId) {
    final uid = _currentUserId();
    if (uid == null) return Stream.value(null);

    // userId is part of the query because the security rules only let
    // people read their own payments.
    return _db
        .collection('payments')
        .where('bookingId', isEqualTo: bookingId)
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'successful')
        .limit(1)
        .snapshots()
        .asyncMap((query) async {
          if (query.docs.isEmpty) return null;
          return _build(bookingId, query.docs.first.data());
        });
  }

  Future<EscrowRecord?> _build(
    String bookingId,
    Map<String, dynamic> payment,
  ) async {
    final booking = (await _db.collection('bookings').doc(bookingId).get())
        .data();
    if (booking == null) return null;

    final tripId = booking['tripId'] as String?;
    final trip = tripId == null
        ? null
        : (await _db.collection('trips').doc(tripId).get()).data();

    return EscrowRecord(
      bookingId: bookingId,
      reference: booking['reference'] as String? ?? '',
      operatorName:
          (trip?['operatorName'] ?? trip?['operator'] ?? 'your operator')
              as String,
      seatNumber: booking['seatNumber'] as String? ?? '',
      amount: (payment['amount'] as num?)?.toInt() ?? 0,
      currency: payment['currency'] as String? ?? 'RWF',
      paymentMethodLabel:
          _methodLabels[payment['method']] ?? 'original payment method',
      stage: EscrowStage.fromName(payment['escrowStatus'] as String?),
      tripConfirmed: booking['status'] == 'paid',
    );
  }
}

class InMemoryEscrowRepository implements EscrowRepository {
  InMemoryEscrowRepository([Map<String, EscrowRecord>? records])
    : _records = records ?? {for (final r in demoRecords) r.bookingId: r};

  final Map<String, EscrowRecord> _records;

  static const demoRecords = [
    EscrowRecord(
      bookingId: 'demo-booking-1',
      reference: 'BME-7K2Q-4C',
      operatorName: 'Trinity Express',
      seatNumber: '4C',
      amount: 18500,
      currency: 'RWF',
      paymentMethodLabel: 'MTN MoMo',
      stage: EscrowStage.held,
      tripConfirmed: true,
    ),
    EscrowRecord(
      bookingId: 'demo-booking-jaguar',
      reference: 'BME-3JG9-2A',
      operatorName: 'Jaguar',
      seatNumber: '2A',
      amount: 15500,
      currency: 'RWF',
      paymentMethodLabel: 'MTN MoMo',
      stage: EscrowStage.refunded,
      tripConfirmed: true,
    ),
  ];

  @override
  Stream<EscrowRecord?> watchEscrow(String bookingId) =>
      Stream.value(_records[bookingId]);
}
