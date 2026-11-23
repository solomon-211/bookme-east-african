import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import '../bloc/auth_bloc.dart';

// First screen after install: brand, promise, and the ways in.
// Dark in both themes, as in the Figma.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _promises = [
    (Icons.verified_user_outlined, 'Verified Operators'),
    (Icons.lock_outline, 'Escrow Payment Protection'),
    (Icons.qr_code_2, 'Instant QR Boarding'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: SafeArea(
          // Scrolls on short screens and in landscape, and fills the
          // height on tall ones so the buttons sit at the bottom.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      const Center(child: BrandLogo(size: 88)),
                      const SizedBox(height: 48),
                      const Text(
                        'Your seat, confirmed before you leave home.',
                        style: TextStyle(
                          fontSize: 30,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Book verified cross-border buses, guaranteed seats, '
                        'zero hidden fees.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 22),
                      for (final (icon, label) in _promises)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(icon, size: 20, color: AppColors.lime),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      _PillButton(
                        key: const Key('get_started'),
                        label: 'Get Started',
                        icon: Icons.arrow_forward,
                        filled: true,
                        onPressed: () => context.push(AppRoutes.phone),
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (p, c) => p.isLoading != c.isLoading,
                        builder: (context, state) => _PillButton(
                          key: const Key('google_sign_in'),
                          label: 'Continue with Google',
                          icon: Icons.g_mobiledata,
                          onPressed: state.isLoading
                              ? null
                              : () => context.read<AuthBloc>().add(
                                  const GoogleSignInRequested(),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        key: const Key('email_sign_in'),
                        onPressed: () => context.push(AppRoutes.login),
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account?  ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            children: const [
                              TextSpan(
                                text: 'Sign in',
                                style: TextStyle(
                                  color: AppColors.lime,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// White filled pill (main action) or outlined pill on the dark background.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: filled ? 18 : 26),
      ],
    );
    const size = Size.fromHeight(54);

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: size,
          shape: const StadiumBorder(),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: size,
        shape: const StadiumBorder(),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}
