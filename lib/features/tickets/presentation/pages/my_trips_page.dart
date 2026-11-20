import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/info_note.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/border_crossing.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/my_trips_cubit.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/trips_tab_cubit.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/border_checklist_card.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/past_trip_tile.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/upcoming_trip_card.dart';

/// Where each My Trips action leads. The screens behind them (ticket,
/// Ready for Journey, Manage Booking) are wired in by the app shell.
class MyTripsActions {
  const MyTripsActions({
    required this.onShowTicket,
    required this.onManage,
    required this.onOpenChecklist,
    required this.onFindBus,
  });

  /// "Show Offline QR" and tapping a past trip.
  final void Function(BuildContext context, Ticket ticket) onShowTicket;
  final void Function(BuildContext context, Ticket ticket) onManage;

  /// "View full checklist & station directions".
  final void Function(BuildContext context, Ticket ticket) onOpenChecklist;

  /// Empty state button, goes to Search.
  final void Function(BuildContext context) onFindBus;
}

/// The My Trips tab. Needs a [TicketsRepository] above it in the tree.
class MyTripsPage extends StatelessWidget {
  const MyTripsPage({required this.actions, super.key});

  final MyTripsActions actions;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) =>
              MyTripsCubit(repository: ctx.read<TicketsRepository>())..load(),
        ),
        BlocProvider(create: (_) => TripsTabCubit()),
      ],
      child: MyTripsView(actions: actions),
    );
  }
}

/// The screen itself, separate from [MyTripsPage] so tests can supply their
/// own cubits.
class MyTripsView extends StatelessWidget {
  const MyTripsView({required this.actions, super.key});

  final MyTripsActions actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<MyTripsCubit, MyTripsState>(
          builder: (context, state) {
            return switch (state.status) {
              MyTripsStatus.loading => _Header.withBody(
                body: Center(child: CircularProgressIndicator()),
              ),
              MyTripsStatus.failure => _Header.withBody(
                body: _ErrorBody(
                  message: state.message,
                  onRetry: () => context.read<MyTripsCubit>().load(),
                ),
              ),
              MyTripsStatus.loaded => _LoadedBody(
                state: state,
                actions: actions,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  /// Header on top, [body] filling the rest of the screen.
  static Widget withBody({required Widget body}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Header(),
      Expanded(child: body),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Trips',
            style: TextStyle(
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Your journey, all in one place',
            style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state, required this.actions});

  final MyTripsState state;
  final MyTripsActions actions;

  @override
  Widget build(BuildContext context) {
    final tab = context.watch<TripsTabCubit>().state;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const _Header(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.isOffline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InfoNote(
                    tone: InfoNoteTone.caution,
                    icon: Icons.cloud_off_rounded,
                    title: 'You\'re offline',
                    message: _offlineMessage(state.lastSyncedAt),
                  ),
                ),
              _TripTabs(
                selected: tab,
                upcomingCount: state.upcoming.length,
                pastCount: state.past.length,
              ),
              const SizedBox(height: 16),
              ...switch (tab) {
                TripsTab.upcoming => _upcomingChildren(context),
                TripsTab.past => _pastChildren(context),
              },
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _upcomingChildren(BuildContext context) {
    final next = state.nextTrip;
    if (next == null) {
      return [
        _EmptyTrips(
          title: 'No upcoming trips',
          message: 'Book a seat and your ticket will appear here.',
          onFindBus: () => actions.onFindBus(context),
        ),
        ..._recentPast(context),
      ];
    }

    final country = borderCountry(next);
    return [
      for (final ticket in state.upcoming) ...[
        UpcomingTripCard(
          ticket: ticket,
          onShowQr: () => actions.onShowTicket(context, ticket),
          onManage: () => actions.onManage(context, ticket),
        ),
        const SizedBox(height: 16),
      ],
      if (country != null) ...[
        BorderChecklistCard(
          country: country,
          checks: borderChecklist(next),
          onViewAll: () => actions.onOpenChecklist(context, next),
        ),
        const SizedBox(height: 16),
      ],
      ..._recentPast(context),
    ];
  }

  /// The two most recent past trips, under the upcoming ones.
  List<Widget> _recentPast(BuildContext context) {
    if (state.past.isEmpty) return const [];
    return [
      const Text(
        'Recent past trips',
        style: TextStyle(
          fontSize: 18,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: 16),
      ..._pastTiles(context, state.past.take(2)),
    ];
  }

  List<Widget> _pastChildren(BuildContext context) {
    if (state.past.isEmpty) {
      return [
        _EmptyTrips(
          title: 'No past trips yet',
          message: 'Trips you have taken or cancelled will show here.',
          onFindBus: () => actions.onFindBus(context),
        ),
      ];
    }
    return _pastTiles(context, state.past);
  }

  List<Widget> _pastTiles(BuildContext context, Iterable<Ticket> tickets) => [
    for (final ticket in tickets) ...[
      PastTripTile(
        ticket: ticket,
        onTap: () => actions.onShowTicket(context, ticket),
      ),
      const SizedBox(height: 16),
    ],
  ];

  static String _offlineMessage(DateTime? syncedAt) {
    if (syncedAt == null) return 'Showing the tickets saved on this phone.';
    return 'Showing tickets saved ${Formatters.shortDate(syncedAt)} at '
        '${Formatters.time(syncedAt)}. Your QR codes still work.';
  }
}

/// "Upcoming · 1" / "Past · 6" pill tabs.
class _TripTabs extends StatelessWidget {
  const _TripTabs({
    required this.selected,
    required this.upcomingCount,
    required this.pastCount,
  });

  final TripsTab selected;
  final int upcomingCount;
  final int pastCount;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripsTabCubit>();
    return Row(
      children: [
        _TabPill(
          label: 'Upcoming · $upcomingCount',
          selected: selected == TripsTab.upcoming,
          onTap: () => cubit.select(TripsTab.upcoming),
        ),
        const SizedBox(width: 8),
        _TabPill(
          label: 'Past · $pastCount',
          selected: selected == TripsTab.past,
          onTap: () => cubit.select(TripsTab.past),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.ink : AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppColors.ink : AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({
    required this.title,
    required this.message,
    required this.onFindBus,
  });

  final String title;
  final String message;
  final VoidCallback onFindBus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            size: 32,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Find a bus', onPressed: onFindBus),
        ],
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
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            message ?? 'We couldn\'t load your trips. Please try again.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
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
