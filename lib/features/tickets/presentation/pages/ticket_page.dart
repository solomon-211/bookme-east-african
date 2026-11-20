import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/info_note.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/border_crossing.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/ticket_cubit.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/digital_ticket_card.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/menu_tile.dart';

/// Dark card behind the escrow message, one step lighter than the page.
const Color _raisedDark = Color(0xFF1A241E);

/// Where the links on the ticket lead. Wired in by the app shell.
class TicketActions {
  const TicketActions({
    required this.onOpenChecklist,
    required this.onOpenEscrowInfo,
    this.onManage,
  });

  /// "View Cross-Border Checklist" (Ready for Journey).
  final void Function(BuildContext context, Ticket ticket) onOpenChecklist;

  /// "View Escrow Info" (Where your money is).
  final void Function(BuildContext context, Ticket ticket) onOpenEscrowInfo;

  /// "Manage booking": change, cancel or remove from history. The row is
  /// hidden when this is left out.
  final void Function(BuildContext context, Ticket ticket)? onManage;
}

/// The Digital Ticket ("Seat Booked") for one booking. Needs a
/// [TicketsRepository] above it in the tree.
class TicketPage extends StatelessWidget {
  const TicketPage({required this.bookingId, required this.actions, super.key});

  final String bookingId;
  final TicketActions actions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TicketCubit(
        repository: ctx.read<TicketsRepository>(),
        bookingId: bookingId,
      )..load(),
      child: TicketView(actions: actions),
    );
  }
}

/// The screen itself, separate from [TicketPage] so tests can supply their
/// own cubit.
class TicketView extends StatelessWidget {
  const TicketView({required this.actions, super.key});

  final TicketActions actions;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TicketCubit, TicketState>(
      listenWhen: (before, now) =>
          now.savedAt != null && before.savedAt != now.savedAt,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Ticket saved on this phone. The QR code works without '
                'internet.',
              ),
            ),
          );
      },
      child: BlocBuilder<TicketCubit, TicketState>(
        builder: (context, state) {
          final ticket = state.ticket;
          return Scaffold(
            backgroundColor: AppColors.ink,
            appBar: AppBar(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 44,
            ),
            body: switch (state.status) {
              TicketStatus.loading => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              TicketStatus.failure => _ErrorBody(
                message: state.message,
                onRetry: () => context.read<TicketCubit>().load(),
              ),
              TicketStatus.loaded => _TicketBody(
                ticket: ticket!,
                state: state,
                actions: actions,
              ),
            },
            bottomNavigationBar: ticket == null || ticket.isCancelled
                ? null
                : _SaveBar(
                    onSave: () => context.read<TicketCubit>().saveToPhone(),
                  ),
          );
        },
      ),
    );
  }
}

class _TicketBody extends StatelessWidget {
  const _TicketBody({
    required this.ticket,
    required this.state,
    required this.actions,
  });

  final Ticket ticket;
  final TicketState state;
  final TicketActions actions;

  @override
  Widget build(BuildContext context) {
    final booking = ticket.booking;
    final paid = Formatters.money(booking.totalAmount, booking.currency);
    final crossesBorder = borderCountry(ticket) != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          ticket.isCancelled ? 'Booking Cancelled' : 'Seat Booked',
          style: const TextStyle(
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          ticket.isCancelled
              ? 'Ref ${booking.reference}'
              : 'Paid $paid · Ref ${booking.reference}',
          style: const TextStyle(
            fontSize: 11,
            height: 1.4,
            color: Color(0xFF969FA2),
          ),
        ),
        const SizedBox(height: 24),
        if (state.isOffline) ...[
          const InfoNote(
            tone: InfoNoteTone.caution,
            icon: Icons.cloud_off_rounded,
            title: 'You\'re offline',
            message:
                'Showing the ticket saved on this phone. The QR code still '
                'works at boarding.',
          ),
          const SizedBox(height: 16),
        ],
        DigitalTicketCard(ticket: ticket),
        const SizedBox(height: 16),
        if (!ticket.isCancelled) ...[
          _EscrowCard(amount: paid),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Send SMS Receipt',
            icon: Icons.sms_outlined,
            style: PrimaryButtonStyle.outlined,
            onPressed: () => _sendReceipt(context, ticket, paid),
          ),
          const SizedBox(height: 16),
        ],
        if (crossesBorder) ...[
          MenuTile(
            icon: Icons.checklist_rounded,
            title: 'View Cross-Border Checklist',
            subtitle: 'Prepare documents before travel',
            onTap: () => actions.onOpenChecklist(context, ticket),
          ),
          const SizedBox(height: 16),
        ],
        MenuTile(
          icon: Icons.verified_user_outlined,
          title: 'View Escrow Info',
          subtitle: ticket.isCancelled
              ? 'See where your refund is'
              : 'Held until verified boarding',
          onTap: () => actions.onOpenEscrowInfo(context, ticket),
        ),
        const SizedBox(height: 16),
        if (actions.onManage case final manage?) ...[
          MenuTile(
            icon: Icons.tune_rounded,
            title: 'Manage booking',
            subtitle: ticket.isPaid
                ? 'Change date, cancel or remove from history'
                : 'Remove from history',
            onTap: () => manage(context, ticket),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Ticket stored on this phone · No internet needed to show QR',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, height: 1.4, color: Color(0xFF969FA2)),
        ),
      ],
    );
  }

  /// Opens the SMS app with the receipt ready to send to the passenger's
  /// own number (or any number they choose).
  static Future<void> _sendReceipt(
    BuildContext context,
    Ticket ticket,
    String paid,
  ) async {
    final booking = ticket.booking;
    final trip = ticket.trip;
    final body =
        'BookMe ticket ${booking.reference}: '
        '${trip.fromCode} → ${trip.toCode}, '
        '${Formatters.shortDate(trip.departure)} '
        '${Formatters.time(trip.departure)}, '
        '${trip.operatorName}, seat ${booking.seatNumber}. Paid $paid.';
    final uri = Uri(
      scheme: 'sms',
      path: booking.passenger?.phone ?? '',
      queryParameters: {'body': body},
    );
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No SMS app found on this phone.')),
      );
    }
  }
}

class _EscrowCard extends StatelessWidget {
  const _EscrowCard({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _raisedDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppColors.lime,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your money. Protected.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'BookMe holds $amount in escrow. Funds are released ONLY '
                  'after successful, verified boarding.',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white,
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

/// "Save to Phone / Wallet", pinned under the scrolling ticket.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ink,
        border: Border(top: BorderSide(color: _raisedDark)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: PrimaryButton(
          label: 'Save to Phone / Wallet',
          icon: Icons.download_rounded,
          style: PrimaryButtonStyle.outlined,
          onPressed: onSave,
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            message ?? 'We couldn\'t load this ticket. Please try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Try again',
            style: PrimaryButtonStyle.outlined,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
