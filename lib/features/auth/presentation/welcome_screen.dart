import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                height: 84,
                width: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'BookMe East Africa',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Compare operators, pick your seat, pay with mobile money '
                'and board with a QR code. No station queues.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue with phone',
                onPressed: () => context.push(AppRoutes.phone),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.login),
                icon: const Icon(Icons.mail_outline),
                label: const Text('Continue with email'),
              ),
              const SizedBox(height: 12),
              BlocBuilder<AuthBloc, AuthState>(
                buildWhen: (p, c) => p.isLoading != c.isLoading,
                builder: (context, state) => OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => context.read<AuthBloc>().add(
                          const GoogleSignInRequested(),
                        ),
                  icon: const Icon(Icons.g_mobiledata, size: 30),
                  label: const Text('Continue with Google'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
