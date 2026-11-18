import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/alerts_repository.dart';
import '../domain/app_alert.dart';

// Alerts live under each user: users/{uid}/alerts/{alertId}.
// Keeping them in a subcollection means the security rule is simply
// "only the owner", with no userId field to forget.
class AlertsRepositoryImpl implements AlertsRepository {
  AlertsRepositoryImpl({
    required FirebaseFirestore firestore,
    required String? Function() currentUserId,
  }) : _db = firestore,
       _currentUserId = currentUserId; // ignore: prefer_initializing_formals

  final FirebaseFirestore _db;
  final String? Function() _currentUserId;

  // Older alerts are still in Firestore, we just don't load them all.
  static const _pageSize = 50;

  CollectionReference<Map<String, dynamic>> _alerts() {
    final uid = _currentUserId();
    if (uid == null) throw StateError('Not signed in');
    return _db.collection('users').doc(uid).collection('alerts');
  }

  @override
  Stream<List<AppAlert>> watchAlerts() {
    if (_currentUserId() == null) return Stream.value(const []);
    return _alerts()
        .orderBy('createdAt', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map((snap) => [for (final d in snap.docs) fromMap(d.id, d.data())]);
  }

  @override
  Future<void> addAlert(AppAlert alert) {
    final ref = alert.id.isEmpty ? _alerts().doc() : _alerts().doc(alert.id);
    return ref.set(toMap(alert));
  }

  @override
  Future<void> markRead(String alertId) =>
      _alerts().doc(alertId).update({'read': true});

  @override
  Future<void> deleteAlert(String alertId) => _alerts().doc(alertId).delete();

  static Map<String, dynamic> toMap(AppAlert alert) => {
    'kind': alert.kind.name,
    'title': alert.title,
    'body': alert.body,
    'actionLabel': alert.actionLabel,
    'bookingId': alert.bookingId,
    'read': alert.read,
    'createdAt': Timestamp.fromDate(alert.createdAt),
  };

  static AppAlert fromMap(String id, Map<String, dynamic> map) {
    final created = map['createdAt'];
    return AppAlert(
      id: id,
      kind: AlertKind.fromName(map['kind'] as String?),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      actionLabel: map['actionLabel'] as String?,
      bookingId: map['bookingId'] as String?,
      read: map['read'] as bool? ?? false,
      // A pending serverTimestamp reads as null until the write lands.
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }
}

// Same behaviour without Firebase, for the offline demo and tests.
class InMemoryAlertsRepository implements AlertsRepository {
  InMemoryAlertsRepository([List<AppAlert>? alerts]) : _alerts = [...?alerts];

  final List<AppAlert> _alerts;
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  @override
  Stream<List<AppAlert>> watchAlerts() async* {
    yield _sorted();
    await for (final _ in _changes.stream) {
      yield _sorted();
    }
  }

  List<AppAlert> _sorted() =>
      [..._alerts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> addAlert(AppAlert alert) async {
    final id = alert.id.isEmpty ? 'alert-${_nextId++}' : alert.id;
    _alerts
      ..removeWhere((a) => a.id == id)
      ..add(
        AppAlert(
          id: id,
          kind: alert.kind,
          title: alert.title,
          body: alert.body,
          createdAt: alert.createdAt,
          actionLabel: alert.actionLabel,
          bookingId: alert.bookingId,
          read: alert.read,
        ),
      );
    _changes.add(null);
  }

  @override
  Future<void> markRead(String alertId) async {
    final i = _alerts.indexWhere((a) => a.id == alertId);
    if (i == -1) return;
    _alerts[i] = _alerts[i].copyWith(read: true);
    _changes.add(null);
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    _alerts.removeWhere((a) => a.id == alertId);
    _changes.add(null);
  }

  // The five cards from the Figma design, timed relative to [now].
  static List<AppAlert> demoAlerts(DateTime now) => [
    AppAlert(
      id: 'delay',
      kind: AlertKind.delay,
      title: 'Delay over 2 hours · Refund triggered',
      body:
          'Trinity Express · Fri 2 Oct: departure changed from 21:00 to '
          '23:20. Your full 18,500 RWF refund is automatic.',
      actionLabel: 'Track automatic refund',
      bookingId: 'demo-booking-1',
      createdAt: now,
    ),
    AppAlert(
      id: 'seat',
      kind: AlertKind.seatOpened,
      title: 'A seat opened up',
      body:
          'Volcano Express · Fri 2 Oct · 07:00 Kigali → Kampala. A seat is '
          'available; book before it\'s taken.',
      actionLabel: 'View available seat',
      createdAt: now.subtract(const Duration(minutes: 12)),
    ),
    AppAlert(
      id: 'price',
      kind: AlertKind.priceWatch,
      title: 'Your price watch: Kigali → Nairobi',
      body:
          'Saved route now from 4,200 KES. Compare verified operators and '
          'all-inclusive fares.',
      actionLabel: 'See buses',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    AppAlert(
      id: 'escrow',
      kind: AlertKind.paymentProtected,
      title: 'Payment protected in escrow',
      body:
          'BME-7K2Q-4C · 18,500 RWF was received. Funds stay held until '
          'successful, verified boarding.',
      actionLabel: 'View escrow timeline',
      bookingId: 'demo-booking-1',
      createdAt: now.subtract(const Duration(hours: 5)),
      read: true,
    ),
    AppAlert(
      id: 'refund',
      kind: AlertKind.refundReceived,
      title: 'Cancelled trip · Refund received',
      body:
          'Your previous Jaguar trip was cancelled. The full refund was '
          'returned to your original payment method.',
      actionLabel: 'View refund receipt',
      bookingId: 'demo-booking-jaguar',
      createdAt: DateTime(now.year, 9, 14, 10),
      read: true,
    ),
  ];
}
