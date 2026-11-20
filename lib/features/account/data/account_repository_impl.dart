import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/account_repository.dart';
import '../domain/saved_passenger.dart';
import '../domain/user_profile.dart';

// users/{uid}                     - profile (Auth creates it at sign-up)
// users/{uid}/passengers/{id}     - saved passengers
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _db = firestore,
       _auth = auth; // ignore: prefer_initializing_formals

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _userDoc() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AccountFailure('Please sign in again.');
    }
    return _db.collection('users').doc(user.uid);
  }

  CollectionReference<Map<String, dynamic>> _passengers() =>
      _userDoc().collection('passengers');

  @override
  Stream<UserProfile?> watchProfile() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _userDoc().snapshots().map(
      (snap) => profileFromMap(user.uid, snap.data() ?? const {}, user: user),
    );
  }

  @override
  Future<void> updateProfile(UserProfile profile) => _write(
    () => _userDoc().set({
      ...profileToMap(profile),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
  );

  @override
  Stream<List<SavedPassenger>> watchPassengers() {
    if (_auth.currentUser == null) return Stream.value(const []);
    return _passengers()
        .orderBy('createdAt')
        .snapshots()
        .map((s) => [for (final d in s.docs) passengerFromMap(d.id, d.data())]);
  }

  @override
  Future<SavedPassenger> addPassenger(SavedPassenger passenger) async {
    final ref = _passengers().doc();
    await _write(
      () => ref.set({
        ...passengerToMap(passenger),
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
    return passenger.copyWith(id: ref.id);
  }

  @override
  Future<void> updatePassenger(SavedPassenger passenger) => _write(
    () => _passengers().doc(passenger.id).update({
      ...passengerToMap(passenger),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> deletePassenger(String passengerId) =>
      _write(() => _passengers().doc(passengerId).delete());

  // Turn Firestore errors into a sentence the user can act on.
  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseException catch (e) {
      throw AccountFailure(switch (e.code) {
        'permission-denied' => 'You can only change your own account.',
        'unavailable' => 'You\'re offline. We\'ll save it when you reconnect.',
        'not-found' => 'That item was already removed.',
        _ => 'Something went wrong. Please try again.',
      });
    }
  }

  // Field names match what the Auth feature writes at sign-up
  // (displayName, phoneNumber, email).
  static Map<String, dynamic> profileToMap(UserProfile p) => {
    'displayName': p.fullName,
    'phoneNumber': p.phone,
    'email': p.email,
    'idDocument': p.idDocument == null
        ? null
        : {
            'type': p.idDocument!.type,
            'country': p.idDocument!.country,
            'number': p.idDocument!.number,
          },
    'mobileMoney': p.mobileMoney == null
        ? null
        : {'provider': p.mobileMoney!.provider, 'phone': p.mobileMoney!.phone},
  };

  static UserProfile profileFromMap(
    String uid,
    Map<String, dynamic> map, {
    User? user,
  }) {
    final id = map['idDocument'];
    final momo = map['mobileMoney'];
    final phone = map['phoneNumber'] as String? ?? user?.phoneNumber ?? '';

    return UserProfile(
      uid: uid,
      fullName: map['displayName'] as String? ?? user?.displayName ?? '',
      phone: phone,
      email: map['email'] as String? ?? user?.email,
      // Verified means Firebase Auth confirmed it by SMS.
      phoneVerified: user?.phoneNumber != null && user!.phoneNumber == phone,
      idDocument: id is Map
          ? IdDocument(
              type: id['type'] as String? ?? 'EAC ID',
              country: id['country'] as String? ?? '',
              number: id['number'] as String? ?? '',
            )
          : null,
      mobileMoney: momo is Map
          ? MobileMoneyAccount(
              provider: momo['provider'] as String? ?? 'MTN MoMo',
              phone: momo['phone'] as String? ?? '',
            )
          : null,
    );
  }

  static Map<String, dynamic> passengerToMap(SavedPassenger p) => {
    'fullName': p.fullName,
    'phone': p.phone,
    'idNumber': p.idNumber,
    'nationality': p.nationality,
  };

  static SavedPassenger passengerFromMap(String id, Map<String, dynamic> m) =>
      SavedPassenger(
        id: id,
        fullName: m['fullName'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        idNumber: m['idNumber'] as String? ?? '',
        nationality: m['nationality'] as String? ?? '',
      );
}
