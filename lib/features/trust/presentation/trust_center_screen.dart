import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/nav_tile.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/surface_card.dart';
import '../domain/trust_repository.dart';
import 'help_center_sheet.dart';
import 'operator_rating_tile.dart';
import 'refund_policy_card.dart';
import 'trust_cubit.dart';

class TrustCenterScreen extends StatelessWidget {
  const TrustCenterScreen({this.bookingReference, super.key});

  // Shown in the footer when the user has an active booking.
  final String? bookingReference;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrustCubit(context.read<TrustRepository>())..load(),
      child: _TrustCenterView(bookingReference: bookingReference),
    );
  }
}

class _TrustCenterView extends StatelessWidget {
  const _TrustCenterView({this.bookingReference});

  final String? bookingReference;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final footer = bookingReference == null
        ? 'Keep your booking reference handy. Never share a PIN or OTP with '
              'support.'
        : 'Keep your booking reference handy: $bookingReference. Never share '
              'a PIN or OTP with support.';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            const PageHeader(
              title: 'Trust Center',
              subtitle: 'Built around your protection',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _ConfidenceBanner(),
                  const SizedBox(height: 20),
                  const SectionHeading('Verified operators & safety ratings'),
                  const _OperatorsCard(),
                  const SizedBox(height: 20),
                  const SectionHeading('Full refund policy'),
                  const RefundPolicyCard(),
                  const SizedBox(height: 16),
                  NavTile(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    subtitle:
                        'Get help with refunds, payments, boarding or a '
                        'safety concern.',
                    onTap: () => showHelpCenter(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    footer,
                    style: TextStyle(fontSize: 12.5, color: palette.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBanner extends StatelessWidget {
  const _ConfidenceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppPalette.statusCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: AppColors.lime, size: 26),
          SizedBox(height: 18),
          Text(
            'Travel with confidence.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Verified operators. Transparent fares. Escrow until successful, '
            'verified boarding.',
            style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _OperatorsCard extends StatelessWidget {
  const _OperatorsCard();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: BlocBuilder<TrustCubit, TrustState>(
        builder: (context, state) {
          switch (state.status) {
            case TrustStatus.loading:
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            case TrustStatus.failure:
              return Column(
                children: [
                  Text(
                    'We couldn\'t load operator ratings.',
                    style: TextStyle(color: palette.text),
                  ),
                  TextButton(
                    onPressed: () => context.read<TrustCubit>().load(),
                    child: const Text('Try again'),
                  ),
                ],
              );
            case TrustStatus.ready:
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final op in state.operators)
                    OperatorRatingTile(operator: op),
                  const SizedBox(height: 8),
                  Text(
                    'Safety ratings reflect verified passenger feedback. '
                    'Checks don\'t guarantee an incident-free journey.',
                    style: TextStyle(fontSize: 11.5, color: palette.muted),
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}
