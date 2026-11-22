import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Profile stored in the Firestore `users/{uid}` document.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.preferredPayment,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;

  /// Key of [paymentMethods] (e.g. `mtn_momo`). Stored in Firestore only.
  final String? preferredPayment;

  factory AppUser.fromFirebase(
    User user, {
    String? displayName,
    String? preferredPayment,
  }) => AppUser(
    uid: user.uid,
    displayName: displayName ?? user.displayName,
    email: user.email,
    phoneNumber: user.phoneNumber,
    photoUrl: user.photoURL,
    preferredPayment: preferredPayment,
  );

  /// Name to show in the UI, falling back to email/phone.
  String get label {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    return email ?? phoneNumber ?? 'Traveler';
  }

  @override
  List<Object?> get props => [
    uid,
    displayName,
    email,
    phoneNumber,
    photoUrl,
    preferredPayment,
  ];
}
