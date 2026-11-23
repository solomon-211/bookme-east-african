import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/journey_checklist_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/border_crossing.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/ready_for_journey_cubit.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/page_header.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/trip_route_row.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/upcoming_trip_card.dart';

/// Where the buttons on Ready for Journey lead. Wired in by the app shell.
class ReadyForJourneyActions {
  const ReadyForJourneyActions({
    required this.onShowOfflineQr,
    required this.onManage,
  });

  final void Function(BuildContext context, Ticket ticket) onShowOfflineQr;
  final void Function(BuildContext context, Ticket ticket) onManage;
}

/// "Ready for your journey?": trip summary, where to be and when, and the
/// cross-border document checklist. Needs a [TicketsRepository] and a
/// [JourneyChecklistRepository] above it in the tree.
class ReadyForJourneyPage extends StatelessWidget {
  const ReadyForJourneyPage({
    required this.ticket,
    required this.actions,
    this.clock,
    super.key,
  });

  final Ticket ticket;
  final ReadyForJourneyActions actions;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ReadyForJourneyCubit(
        tickets: ctx.read<TicketsRepository>(),
        checklist: ctx.read<JourneyChecklistRepository>(),
        ticket: ticket,
      )..load(),
      child: ReadyForJourneyView(actions: actions, clock: clock),
    );
  }
}

/// The screen itself, separate from [ReadyForJourneyPage] so tests can
/// supply their own cubit.
class ReadyForJourneyView extends StatelessWidget {
  const ReadyForJourneyView({required this.actions, this.clock, super.key});

  final ReadyForJourneyActions actions;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final ticket = context.read<ReadyForJourneyCubit>().ticket;
    final now = (clock ?? DateTime.now)();
    final country = borderCountry(ticket);
    final passenger = ticket.booking.passenger?.fullName;

    return BlocConsumer<ReadyForJourneyCubit, ReadyForJourneyState>(
      listenWhen: (before, after) =>
          after.message != null && before.message != after.message,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message!))),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.palette.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  title: 'Ready for your journey?',
                  subtitle: passenger == null
                      ? ticket.booking.reference
                      : '${ticket.booking.reference} · $passenger',
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      _TripCard(
                        ticket: ticket,
                        savedOffline: state.savedOffline,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Show Offline Boarding QR',
                        icon: Icons.qr_code_2_rounded,
                        style: PrimaryButtonStyle.outlined,
                        onPressed: () =>
                            actions.onShowOfflineQr(context, ticket),
                      ),
                      const SizedBox(height: 16),
                      _StationCard(ticket: ticket),
                      if (country != null) ...[
                        const SizedBox(height: 16),
                        _DocumentChecklist(
                          items: travelDocumentChecklist(country),
                          checked: state.checked,
                          onToggle: context.read<ReadyForJourneyCubit>().toggle,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: ticket.canManage(now)
              ? _ManageBar(onManage: () => actions.onManage(context, ticket))
              : null,
        );
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.ticket, required this.savedOffline});

  final Ticket ticket;
  final bool savedOffline;

  @override
  Widget build(BuildContext context) {
    final trip = ticket.trip;
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusChip(ticket: ticket),
          const SizedBox(height: 12),
          TripRouteRow(trip: trip),
          const SizedBox(height: 8),
          Text(
            '${Formatters.shortDate(trip.departure)} → '
            '${Formatters.shortDate(trip.arrival)} · '
            '${trip.operatorName} · Seat ${ticket.booking.seatNumber}',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: context.palette.muted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            savedOffline
                ? 'Offline QR is saved on this phone'
                : 'Open the QR once while online to save it on this phone',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: savedOffline
                  ? AppColors.success
                  : context.palette.warningText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = ticket.isCancelled
        ? (Icons.cancel_outlined, 'Cancelled')
        : (Icons.check_circle_outline, 'Confirmed · Not yet boarded');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.ink),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Be at Nyabugogo by 20:30" with a link to real directions.
class _StationCard extends StatelessWidget {
  const _StationCard({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final trip = ticket.trip;
    final boarding = trip.departure.subtract(kBoardingWindow);
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Be at ${trip.fromStation} by ${Formatters.time(boarding)}',
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: context.palette.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Boarding opens ${kBoardingWindow.inMinutes} minutes before '
            'departure. Show your QR to the ${trip.operatorName} conductor.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: context.palette.muted,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _openDirections(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.success,
            ),
            child: const Text(
              'Station directions →',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    final trip = ticket.trip;
    final city = cityName(trip.fromCode, station: trip.fromStation);
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${trip.fromStation} bus station, $city',
    });
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Couldn\'t open maps on this phone.')),
      );
    }
  }
}

class _DocumentChecklist extends StatelessWidget {
  const _DocumentChecklist({
    required this.items,
    required this.checked,
    required this.onToggle,
  });

  final List<TravelDocumentCheck> items;
  final Set<String> checked;
  final void Function(String itemId) onToggle;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cross-border checklist',
            style: TextStyle(
              fontSize: 18,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: context.palette.text,
            ),
          ),
          for (final item in items) ...[
            const SizedBox(height: 4),
            _DocumentRow(
              item: item,
              checked: checked.contains(item.id),
              onTap: () => onToggle(item.id),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Confirm with official immigration and health authorities. This '
            'checklist is guidance, not an entry guarantee.',
            style: TextStyle(
              fontSize: 10,
              height: 1.4,
              color: context.palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.item,
    required this.checked,
    required this.onTap,
  });

  final TravelDocumentCheck item;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: checked ? AppColors.success : context.palette.card,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: checked ? AppColors.success : context.palette.border,
                  ),
                ),
                child: checked
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: context.palette.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.detail,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: context.palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
      ),
      child: child,
    );
  }
}

class _ManageBar extends StatelessWidget {
  const _ManageBar({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.card,
        border: Border(top: BorderSide(color: context.palette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: PrimaryButton(label: 'Manage Booking', onPressed: onManage),
      ),
    );
  }
}
