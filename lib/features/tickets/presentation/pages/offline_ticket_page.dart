import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/offline_ticket_cubit.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/digital_ticket_card.dart';

/// "Show Offline QR": just the ticket card, read from the phone, sized to
/// hold up to a scanner. Needs a [TicketsRepository] above it in the tree.
class OfflineTicketPage extends StatelessWidget {
  const OfflineTicketPage({
    required this.bookingId,
    this.ticket,
    this.onOpenFullTicket,
    super.key,
  });

  final String bookingId;

  /// The ticket the caller already has, used if the phone has no copy yet.
  final Ticket? ticket;

  /// Opens the full Digital Ticket screen (live version, receipts, links).
  final void Function(BuildContext context, Ticket ticket)? onOpenFullTicket;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => OfflineTicketCubit(
        repository: ctx.read<TicketsRepository>(),
        bookingId: bookingId,
        fallback: ticket,
      )..load(),
      child: OfflineTicketView(onOpenFullTicket: onOpenFullTicket),
    );
  }
}

/// The screen itself, separate from [OfflineTicketPage] so tests can supply
/// their own cubit.
class OfflineTicketView extends StatelessWidget {
  const OfflineTicketView({this.onOpenFullTicket, super.key});

  final void Function(BuildContext context, Ticket ticket)? onOpenFullTicket;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 44,
      ),
      body: BlocBuilder<OfflineTicketCubit, OfflineTicketState>(
        builder: (context, state) {
          final ticket = state.ticket;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const Text(
                'Offline Ticket',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _savedLabel(state),
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: Color(0xFF969FA2),
                ),
              ),
              const SizedBox(height: 24),
              if (ticket == null)
                const _NotSaved()
              else ...[
                DigitalTicketCard(ticket: ticket),
                const SizedBox(height: 16),
                const Text(
                  'Turn your screen brightness up when the conductor scans.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF969FA2),
                  ),
                ),
                if (onOpenFullTicket != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => onOpenFullTicket!(context, ticket),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.lime,
                      ),
                      child: const Text(
                        'Open full ticket',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  static String _savedLabel(OfflineTicketState state) {
    final savedAt = state.savedAt;
    if (state.isMissing) return 'Not saved on this phone yet';
    if (savedAt == null) return 'Saved on this phone · No internet needed';
    return 'Saved ${Formatters.shortDate(savedAt)} at '
        '${Formatters.time(savedAt)} · No internet needed';
  }
}

class _NotSaved extends StatelessWidget {
  const _NotSaved();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 32, color: AppColors.muted),
          SizedBox(height: 12),
          Text(
            'This ticket isn\'t saved on this phone',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Connect to the internet once and open My Trips. Your tickets '
            'are then saved for offline use.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
