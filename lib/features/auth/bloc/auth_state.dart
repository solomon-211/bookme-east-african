part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.infoMessage,
    this.phoneNumber,
    this.verificationId,
    this.resendToken,
  });

  const AuthState.unknown() : this();
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  const AuthState.authenticated(AppUser user)
    : this(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;

  /// Phone sign-in flow data.
  final String? phoneNumber;
  final String? verificationId;
  final int? resendToken;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    String? phoneNumber,
    String? verificationId,
    int? resendToken,
    bool clearMessages = false,
    bool clearPhoneFlow = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearMessages ? null : (infoMessage ?? this.infoMessage),
      phoneNumber: clearPhoneFlow ? null : (phoneNumber ?? this.phoneNumber),
      verificationId: clearPhoneFlow
          ? null
          : (verificationId ?? this.verificationId),
      resendToken: clearPhoneFlow ? null : (resendToken ?? this.resendToken),
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    isLoading,
    errorMessage,
    infoMessage,
    phoneNumber,
    verificationId,
    resendToken,
  ];
}
