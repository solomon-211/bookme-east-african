import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/core/widgets/choice_pill.dart';
import 'package:bookme_summative_project/core/widgets/page_header.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/entities/trip_filter.dart';
import 'package:bookme_summative_project/features/search/presentation/bloc/search_bloc.dart';
import 'package:bookme_summative_project/features/search/presentation/cubits/waitlist_cubit.dart';
import 'package:bookme_summative_project/features/search/presentation/pages/filters_page.dart';
import 'package:bookme_summative_project/features/search/presentation/pages/trip_details_page.dart';
import 'package:bookme_summative_project/features/search/presentation/pages/waitlist_dialog.dart';
import 'package:bookme_summative_project/features/search/presentation/search_navigation.dart';
import 'package:bookme_summative_project/features/search/presentation/widgets/search_format.dart';
import 'package:bookme_summative_project/features/search/presentation/widgets/trip_result_card.dart';

/// Screen 2: buses on the chosen route and day.
class SearchResultsPage extends StatelessWidget {
  const SearchResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WaitlistCubit, WaitlistState>(
      listenWhen: (a, b) =>
          b.errorMessage != null && a.errorMessage != b.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        context.read<WaitlistCubit>().clearError();
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              final q = state.query;
              final count = state.visibleTrips.length;
              final subtitle = [
                Formatters.shortDate(state.selectedDay),
                q.passengerLabel,
                if (state.status == ResultsStatus.success)
                  '$count bus${count == 1 ? '' : 'es'}',
              ].join(' · ');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: '${q.origin.name} → ${q.destination.name}',
                    subtitle: subtitle,
                  ),
                  _DateStrip(state: state),
                  const SizedBox(height: 12),
                  _QuickFilters(state: state),
                  const SizedBox(height: 8),
                  Expanded(child: _Body(state: state)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final loading = state.status == ResultsStatus.loading;
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final day = state.days[i];
          final selected = day == state.selectedDay;
          final fare = loading ? null : state.lowestFareOn(day);
          final weekday = Formatters.shortDate(day).split(' ').first;
          final fg = selected ? Colors.white : palette.text;
          return Semantics(
            selected: selected,
            button: true,
            label: '${Formatters.shortDate(day)}, '
                '${fare == null ? 'no seats' : 'from ${Formatters.money(fare, state.currency)}'}',
            excludeSemantics: true,
            child: Material(
              color: selected ? AppColors.ink : palette.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: selected ? AppColors.ink : palette.border,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () =>
                    context.read<SearchBloc>().add(SearchDaySelected(day)),
                child: SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(weekday, style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : palette.muted)),
                      Text('${day.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg)),
                      Text(
                        fare == null ? '—' : SearchFormat.compact(fare),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: selected ? AppColors.lime : palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickFilters extends StatelessWidget {
  const _QuickFilters({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SearchBloc>();
    final f = state.filter;
    final night = f.window == DepartureWindow.night;
    final wifi = f.amenities.contains(Amenity.wifi);
    final count = f.activeCount;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ChoicePill(
            label: 'All',
            selected: !f.isActive,
            onTap: () => bloc.add(const SearchFilterChanged(TripFilter.none)),
          ),
          const SizedBox(width: 8),
          ChoicePill(
            label: 'Night',
            selected: night,
            onTap: () => bloc.add(
              SearchFilterChanged(
                f.copyWith(
                  window: night ? DepartureWindow.any : DepartureWindow.night,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ChoicePill(
            label: 'Wi-Fi',
            selected: wifi,
            onTap: () =>
                bloc.add(SearchFilterChanged(f.toggleAmenity(Amenity.wifi))),
          ),
          const SizedBox(width: 8),
          ChoicePill(
            label: count == 0 ? 'Filters' : 'Filters ($count)',
            selected: false,
            onTap: () => openFilters(context),
          ),
        ],
      ),
    );
  }
}

/// Opens "Find your bus" and applies what the traveller chose.
Future<void> openFilters(BuildContext context) async {
  final bloc = context.read<SearchBloc>();
  final chosen = await SearchNavigation.push<TripFilter>(
    context,
    const FiltersPage(),
  );
  if (chosen != null) bloc.add(SearchFilterChanged(chosen));
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bloc = context.read<SearchBloc>();

    switch (state.status) {
      case ResultsStatus.idle:
      case ResultsStatus.loading:
        return const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading buses'),
        );
      case ResultsStatus.failure:
        return _Message(
          icon: Icons.cloud_off_outlined,
          title: 'Couldn\'t load buses',
          body: state.errorMessage ?? 'Please try again.',
          action: 'Try again',
          onAction: () => bloc.add(const SearchRefreshed()),
        );
      case ResultsStatus.success:
        break;
    }

    if (state.dayTrips.isEmpty) {
      return _Message(
        icon: Icons.event_busy_outlined,
        title: 'No buses on this day',
        body: 'Try another day above. Days with a price have seats.',
        action: 'Change search',
        onAction: () => Navigator.of(context).maybePop(),
      );
    }
    final trips = state.visibleTrips;
    if (trips.isEmpty) {
      return _Message(
        icon: Icons.filter_alt_off_outlined,
        title: 'No buses match your filters',
        body: '${state.dayTrips.length} buses run this day. '
            'Loosen a filter to see them.',
        action: 'Reset filters',
        onAction: () => bloc.add(const SearchFilterChanged(TripFilter.none)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(const SearchRefreshed());
        await bloc.stream.firstWhere((s) => s.status != ResultsStatus.loading);
      },
      child: BlocBuilder<WaitlistCubit, WaitlistState>(
        builder: (context, waitlist) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: trips.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Row(
                children: [
                  Icon(Icons.circle, size: 8, color: palette.link),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Live seats · Verified operators · Prices include all fees',
                      style: TextStyle(fontSize: 12, color: palette.link),
                    ),
                  ),
                ],
              );
            }
            final trip = trips[i - 1];
            return TripResultCard(
              trip: trip,
              onWaitlist: waitlist.isOnWaitlist(trip.id),
              busy: waitlist.busyTripId == trip.id,
              onTap: () =>
                  SearchNavigation.push(context, TripDetailsPage(trip: trip)),
              onNotify: () => showWaitlistDialog(context, trip),
              onLeaveWaitlist: () async {
                final ok = await context.read<WaitlistCubit>().leave(trip.id);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You left the waitlist.')),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 24),
        Icon(icon, size: 48, color: palette.muted),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: palette.text),
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center, style: TextStyle(color: palette.muted)),
        const SizedBox(height: 20),
        PrimaryButton(
          label: action,
          onPressed: onAction,
          style: PrimaryButtonStyle.outlined,
        ),
      ],
    );
  }
}
