import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/nav_tile.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/surface_card.dart';
import '../../settings/presentation/departure_city_picker.dart';
import '../../settings/presentation/language_selector.dart';
import '../../settings/presentation/theme_mode_selector.dart';
import '../../trust/presentation/help_center_sheet.dart';
import '../../trust/presentation/refund_policy_screen.dart';
import '../../trust/presentation/trust_center_screen.dart';
import '../domain/account_repository.dart';
import '../domain/user_profile.dart';
import 'account_cubit.dart';
import 'account_state.dart';
import 'edit_profile_sheet.dart';
import 'saved_passengers_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({this.onSignOut, super.key});

  // Auth owns signing out; the shell passes this in.
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AccountCubit(context.read<AccountRepository>())..start(),
      child: _AccountView(onSignOut: onSignOut),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView({this.onSignOut});

  final VoidCallback? onSignOut;

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AccountCubit, AccountState>(
          listenWhen: (a, b) => a.messageId != b.messageId,
          listener: (context, state) => ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message!))),
          builder: (context, state) {
            if (state.status == AccountStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final profile = state.profile;

            return ListView(
              children: [
                const LargePageTitle(
                  title: 'Account',
                  subtitle: 'Your details. Your preferences.',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (profile != null) ...[
                        _ProfileCard(profile: profile),
                        const SizedBox(height: 20),
                        const SectionHeading('Saved for your next journey'),
                        NavTile(
                          key: const Key('ids_tile'),
                          icon: Icons.badge_outlined,
                          title: 'IDs & passports',
                          subtitle:
                              profile.idDocument?.summary ??
                              'Add your passport or EAC ID',
                          onTap: () => showEditProfileSheet(context, profile),
                        ),
                        NavTile(
                          key: const Key('passengers_tile'),
                          icon: Icons.people_outline,
                          title: 'Saved passengers',
                          subtitle: state.passengersSummary,
                          onTap: () => _push(
                            context,
                            BlocProvider.value(
                              value: context.read<AccountCubit>(),
                              child: const SavedPassengersScreen(),
                            ),
                          ),
                        ),
                        NavTile(
                          icon: Icons.phone_android,
                          title: 'Mobile money numbers',
                          subtitle:
                              profile.mobileMoney?.summary ??
                              'Add a MoMo number for faster checkout',
                          onTap: () => showEditProfileSheet(context, profile),
                        ),
                      ] else
                        _SignedOutNote(state: state),
                      const _LanguageCard(),
                      const SizedBox(height: 12),
                      const _PreferencesCard(),
                      const SizedBox(height: 12),
                      NavTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Trust Center',
                        subtitle: 'Verified operators & safety ratings',
                        onTap: () => _push(context, const TrustCenterScreen()),
                      ),
                      NavTile(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                        subtitle: 'Payments, boarding and border guidance',
                        onTap: () => showHelpCenter(context),
                      ),
                      NavTile(
                        icon: Icons.receipt_long_outlined,
                        title: 'Full refund policy',
                        subtitle: 'Your protection, explained clearly',
                        onTap: () => _push(context, const RefundPolicyScreen()),
                      ),
                      if (onSignOut != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          key: const Key('sign_out'),
                          onPressed: onSignOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign out'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final status = profile.phoneVerified ? 'Phone verified' : 'Not verified';

    return SurfaceCard(
      onTap: () => showEditProfileSheet(context, profile),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: AppColors.lime,
            child: Text(
              profile.initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  key: const Key('account_name'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.phone(profile.phone),
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
                const SizedBox(height: 3),
                Text(
                  '$status · Edit profile →',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: palette.link,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Language / Langue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppPalette.of(context).text,
            ),
          ),
          const SizedBox(height: 12),
          const LanguageSelector(),
        ],
      ),
    );
  }
}

// Theme and home city. Not in the Figma frame, but both are saved
// preferences the brief asks for, so they sit next to Language.
class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 12),
          const ThemeModeSelector(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: palette.border),
          ),
          const DepartureCityPicker(),
        ],
      ),
    );
  }
}

class _SignedOutNote extends StatelessWidget {
  const _SignedOutNote({required this.state});

  final AccountState state;

  @override
  Widget build(BuildContext context) {
    final text = state.status == AccountStatus.failure
        ? 'We couldn\'t load your profile. Check your connection.'
        : 'Sign in to see your profile and saved passengers.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: TextStyle(color: AppPalette.of(context).muted)),
    );
  }
}
