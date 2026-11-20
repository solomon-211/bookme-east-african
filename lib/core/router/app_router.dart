import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/phone_sign_in_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/home/home_shell.dart';

class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const phone = '/phone';
  static const otp = '/otp';
  static const login = '/login';
  static const forgot = '/forgot';
  static const home = '/home';
}

/// Re-runs the router redirect whenever the auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter createRouter(AuthBloc bloc) {
  const authRoutes = {
    AppRoutes.welcome,
    AppRoutes.phone,
    AppRoutes.otp,
    AppRoutes.login,
    AppRoutes.forgot,
  };

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefresh(bloc.stream),
    redirect: (context, state) {
      final status = bloc.state.status;
      final loc = state.matchedLocation;

      switch (status) {
        case AuthStatus.unknown:
          return loc == AppRoutes.splash ? null : AppRoutes.splash;
        case AuthStatus.authenticated:
          return (authRoutes.contains(loc) || loc == AppRoutes.splash)
              ? AppRoutes.home
              : null;
        case AuthStatus.unauthenticated:
          return (loc == AppRoutes.splash || loc == AppRoutes.home)
              ? AppRoutes.welcome
              : null;
      }
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(
          path: AppRoutes.phone, builder: (_, __) => const PhoneSignInScreen()),
      GoRoute(path: AppRoutes.otp, builder: (_, __) => const OtpScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.forgot,
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeShell()),
    ],
  );
}
