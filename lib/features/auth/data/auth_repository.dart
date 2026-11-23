import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_user.dart';

/// A user-presentable authentication error.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  factory AuthFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const AuthFailure('That email address is not valid.');
      case 'user-disabled':
        return const AuthFailure('This account has been disabled.');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure('Incorrect email or password.');
      case 'email-already-in-use':
        return const AuthFailure('An account with this email already exists.');
      case 'weak-password':
        return const AuthFailure('Choose a stronger password.');
      case 'too-many-requests':
        return const AuthFailure('Too many attempts. Try again later.');
      case 'network-request-failed':
        return const AuthFailure(
          'No connection. Check your internet and retry.',
        );
      case 'invalid-phone-number':
        return const AuthFailure('That phone number is not valid.');
      case 'invalid-verification-code':
        return const AuthFailure('That code is incorrect. Please try again.');
      case 'session-expired':
        return const AuthFailure('The code expired. Request a new one.');
      case 'quota-exceeded':
        return const AuthFailure('SMS limit reached. Try again later.');
      default:
        return AuthFailure('Something went wrong ($code). Please try again.');
    }
  }

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _google = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;

  /// Emits the restored session on startup, then every sign-in / sign-out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromCode(e.code);
    } on FirebaseException catch (e) {
      throw AuthFailure('Something went wrong (${e.code}). Please try again.');
    }
  }

  // ---------------------------------------------------------------- Email

  Future<void> signInWithEmail(String email, String password) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    await syncUserProfile(user, displayName: name.trim());
    await user.reload();
  });

  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  // --------------------------------------------------------------- Google

  /// Returns false when the user dismissed the Google account picker.
  Future<bool> signInWithGoogle() => _guard(() async {
    final account = await _google.signIn();
    if (account == null) return false;
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
    return true;
  });

  // ---------------------------------------------------------------- Phone

  Future<void> verifyPhone({
    required String phoneNumber,
    int? forceResendingToken,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(String message) onFailed,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: (e) => onFailed(AuthFailure.fromCode(e.code).message),
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> signInWithSmsCode(String verificationId, String smsCode) =>
      signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        ),
      );

  Future<void> signInWithCredential(AuthCredential credential) =>
      _guard(() => _auth.signInWithCredential(credential));

  // -------------------------------------------------------------- Session

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Not signed in with Google; ignore.
    }
    await _auth.signOut();
  }

  // ------------------------------------------------------ users collection

  /// Creates or updates `users/{uid}`. `createdAt` is only written once.
  Future<AppUser> syncUserProfile(User user, {String? displayName}) async {
    final ref = _db.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    final name = displayName ?? user.displayName;

    await ref.set({
      'uid': user.uid,
      if (name != null && name.isNotEmpty) 'displayName': name,
      if (user.email != null) 'email': user.email,
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
        'phoneNumber': user.phoneNumber,
      if (user.photoURL != null) 'photoUrl': user.photoURL,
      'providers': user.providerData.map((p) => p.providerId).toList(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final stored = snapshot.data();
    return AppUser.fromFirebase(
      user,
      displayName: displayName ?? (stored?['displayName'] as String?),
      preferredPayment: stored?['preferredPayment'] as String?,
    );
  }
}
