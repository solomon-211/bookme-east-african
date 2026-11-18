import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/page_header.dart';
import '../../trust/domain/refund_policy.dart';
import '../../trust/presentation/refund_policy_screen.dart';
import '../domain/escrow_record.dart';
import '../domain/escrow_repository.dart';
import 'escrow_cubit.dart';
import 'escrow_timeline.dart';

// "Where your money is": live escrow status for one booking.
class EscrowScreen extends StatelessWidget {
  const EscrowScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EscrowCubit(context.read<EscrowRepository>())..watch(bookingId),
      child: const _EscrowView(),
    );
  }
}

class _EscrowView extends StatelessWidget {
  const _EscrowView();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<EscrowCubit, EscrowState>(
          builder: (context, state) {
            final record = state.record;
            final subtitle = record == null
                ? null
                : '${record.reference} · ${record.operatorName}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(title: 'Where your money is', subtitle: subtitle),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: OutlinedButton(
              key: const Key('view_refund_policy'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: const StadiumBorder(),
                side: BorderSide(color: palette.border),
                foregroundColor: palette.text,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RefundPolicyScreen(),
                ),
              ),
              child: const Text('View Refund Policy'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, EscrowState state) {
    final palette = AppPalette.of(context);

    switch (state.status) {
      case EscrowViewStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case EscrowViewStatus.notFound:
      case EscrowViewStatus.failure:
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              state.status == EscrowViewStatus.notFound
                  ? 'No payment has been received for this booking yet.'
                  : 'We couldn\'t load your escrow status. Check your '
                        'connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted),
            ),
          ),
        );
      case EscrowViewStatus.ready:
        final record = state.record!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            _StatusCard(record: record),
            const SizedBox(height: 16),
            EscrowTimeline(steps: record.steps),
            const SizedBox(height: 16),
            _ProtectionBox(record: record),
          ],
        );
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.record});

  final EscrowRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppPalette.statusCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                record.stage == EscrowStage.refunded
                    ? Icons.replay
                    : Icons.lock_outline,
                size: 18,
                color: AppColors.lime,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  record.statusLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: AppColors.lime,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            record.amountLabel,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            record.statusMessage,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtectionBox extends StatelessWidget {
  const _ProtectionBox({required this.record});

  final EscrowRecord record;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.successSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your refund protection',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: palette.link,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            RefundPolicy.shortProtection,
            style: TextStyle(fontSize: 13, height: 1.4, color: palette.text),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  record.protectedAmountLabel,
                  style: TextStyle(fontSize: 14, color: palette.text),
                ),
              ),
              Text(
                record.amountLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: palette.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
