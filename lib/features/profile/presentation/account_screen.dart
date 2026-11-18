import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';

/// Account tab: shows the signed-in user's name and a sign out button.
/// (Profile editing is left for a later task.)
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    final name = user?.label ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(name,
                      key: const Key('account_name'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 20)),
                ),
              ],
            ),
            const Spacer(),
            OutlinedButton.icon(
              key: const Key('sign_out'),
              onPressed: () =>
                  context.read<AuthBloc>().add(const SignOutRequested()),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
