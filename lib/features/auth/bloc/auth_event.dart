part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Starts listening to the persisted Firebase session.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class EmailSignInRequested extends AuthEvent {
  const EmailSignInRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

class EmailRegisterRequested extends AuthEvent {
  const EmailRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });
  final String name;
  final String email;
  final String password;
  @override
  List<Object?> get props => [name, email, password];
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class PasswordResetRequested extends AuthEvent {
  const PasswordResetRequested(this.email);
  final String email;
  @override
  List<Object?> get props => [email];
}

/// [phoneNumber] must be in E.164 format (e.g. +250788123456).
class PhoneNumberSubmitted extends AuthEvent {
  const PhoneNumberSubmitted(this.phoneNumber, {this.isResend = false});
  final String phoneNumber;
  final bool isResend;
  @override
  List<Object?> get props => [phoneNumber, isResend];
}

class OtpSubmitted extends AuthEvent {
  const OtpSubmitted(this.code);
  final String code;
  @override
  List<Object?> get props => [code];
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

// ---- Internal events (only the bloc adds these) ----

class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final User? user;
  @override
  List<Object?> get props => [user?.uid];
}

class _PhoneCodeSent extends AuthEvent {
  const _PhoneCodeSent(this.verificationId, this.resendToken);
  final String verificationId;
  final int? resendToken;
  @override
  List<Object?> get props => [verificationId, resendToken];
}

class _PhoneAutoVerified extends AuthEvent {
  const _PhoneAutoVerified(this.credential);
  final PhoneAuthCredential credential;
}

class _AuthFailed extends AuthEvent {
  const _AuthFailed(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
