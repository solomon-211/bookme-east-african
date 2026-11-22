import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/app_user.dart';
import '../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
    : _repo = repository,
      super(const AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<_AuthUserChanged>(_onUserChanged);
    on<EmailSignInRequested>(_onEmailSignIn);
    on<EmailRegisterRequested>(_onEmailRegister);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<PasswordResetRequested>(_onPasswordReset);
    on<PhoneNumberSubmitted>(_onPhoneSubmitted);
    on<_PhoneCodeSent>(_onPhoneCodeSent);
    on<_PhoneAutoVerified>(_onPhoneAutoVerified);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<_AuthFailed>(_onFailed);
    on<SignOutRequested>(_onSignOut);
  }

  final AuthRepository _repo;
  StreamSubscription<User?>? _sub;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _sub?.cancel();
    _sub = _repo.authStateChanges.listen((user) => add(_AuthUserChanged(user)));
  }

  Future<void> _onUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user == null) {
      emit(const AuthState.unauthenticated());
      return;
    }
    AppUser profile;
    try {
      profile = await _repo.syncUserProfile(user);
    } catch (_) {
      // Firestore may be unreachable (offline). Don't block the session.
      profile = AppUser.fromFirebase(user);
    }
    emit(AuthState.authenticated(profile));
  }

  // ---------------------------------------------------------------- Email

  Future<void> _onEmailSignIn(
    EmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      await _repo.signInWithEmail(event.email, event.password);
      emit(state.copyWith(isLoading: false));
    } on AuthFailure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> _onEmailRegister(
    EmailRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      await _repo.registerWithEmail(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      // Refresh so the stored display name shows immediately.
      add(_AuthUserChanged(_repo.currentUser));
      emit(state.copyWith(isLoading: false));
    } on AuthFailure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> _onPasswordReset(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      await _repo.sendPasswordReset(event.email);
      emit(
        state.copyWith(
          isLoading: false,
          infoMessage: 'Reset link sent. Check your inbox.',
        ),
      );
    } on AuthFailure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  // --------------------------------------------------------------- Google

  Future<void> _onGoogleSignIn(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      await _repo.signInWithGoogle();
      emit(state.copyWith(isLoading: false));
    } on AuthFailure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  // --------------------------------------------------------------- Phone

  Future<void> _onPhoneSubmitted(
    PhoneNumberSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearMessages: true,
        phoneNumber: event.phoneNumber,
      ),
    );
    try {
      await _repo.verifyPhone(
        phoneNumber: event.phoneNumber,
        forceResendingToken: event.isResend ? state.resendToken : null,
        onCodeSent: (id, token) => add(_PhoneCodeSent(id, token)),
        onAutoVerified: (cred) => add(_PhoneAutoVerified(cred)),
        onFailed: (message) => add(_AuthFailed(message)),
      );
    } on FirebaseAuthException catch (e) {
      add(_AuthFailed(AuthFailure.fromCode(e.code).message));
    }
  }

  void _onPhoneCodeSent(_PhoneCodeSent event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        isLoading: false,
        verificationId: event.verificationId,
        resendToken: event.resendToken,
      ),
    );
  }

  Future<void> _onPhoneAutoVerified(
    _PhoneAutoVerified event,
    Emitter<AuthState> emit,
  ) async {
    // Android can verify the SMS automatically, skipping the OTP screen.
    try {
      await _repo.signInWithCredential(event.credential);
      emit(state.copyWith(isLoading: false));
    } on AuthFailure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final id = state.verificationId;
    if (id == null) {
      emit(state.copyWith(errorMessage: 'Request a new code and try again.'));
      return;
    }
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      await _repo.signInWithSmsCode(id, event.code);
      emit(state.copyWith(isLoading: false));
    } on AuthFailure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  void _onFailed(_AuthFailed event, Emitter<AuthState> emit) {
    emit(state.copyWith(isLoading: false, errorMessage: event.message));
  }

  // ------------------------------------------------------------- Sign out

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.signOut();
    // authStateChanges emits null, which moves the state to unauthenticated.
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
