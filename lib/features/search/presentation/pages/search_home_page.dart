import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/core/widgets/page_header.dart';
import 'package:bookme_summative_project/core/widgets/surface_card.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/search/data/recent_routes_store.dart';
import 'package:bookme_summative_project/features/search/domain/entities/city.dart';
import 'package:bookme_summative_project/features/search/domain/entities/search_query.dart';
import 'package:bookme_summative_project/features/search/presentation/bloc/search_bloc.dart';
import 'package:bookme_summative_project/features/search/presentation/pages/search_results_page.dart';
import 'package:bookme_summative_project/features/search/presentation/search_navigation.dart';

/// Screen 1: "Where to next?" — From, To, dates and passengers.
class SearchHomePage extends StatelessWidget {
  const SearchHomePage({super.key});

  /// Shown under "Book again" before the traveller has searched anything.
  static const popularRoutes = [
    RecentRoute(Cities.kigali, Cities.kampala),
    RecentRoute(Cities.kigali, Cities.nairobi),
    RecentRoute(Cities.kampala, Cities.juba),
  ];

  @override
  Widget build(BuildContext context) {
    final name = SearchNavigation.firstName(context);

    return BlocListener<SearchBloc, SearchState>(
      // Every accepted "Search Buses" opens the results once.
      listenWhen: (a, b) => a.searchCount != b.searchCount,
      listener: (context, _) =>
          SearchNavigation.push(context, const SearchResultsPage()),
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              LargePageTitle(
                title: 'Where to next?',
                subtitle: name == null
                    ? 'Muraho! Cross-border buses you can trust.'
                    : 'Muraho, $name',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _SearchForm(),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _BookAgain(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchForm extends StatelessWidget {
  const _SearchForm();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bloc = context.read<SearchBloc>();

    return BlocBuilder<SearchBloc, SearchState>(
      buildWhen: (a, b) =>
          a.query != b.query ||
          a.formError != b.formError ||
          a.operators != b.operators,
      builder: (context, state) {
        final q = state.query;
        final operators = state.verifiedOperatorCount;
        return SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FieldLabel('FROM'),
              _PickerField(
                icon: Icons.place_outlined,
                text: q.origin.label,
                semanticsLabel: 'From ${q.origin.label}. Change',
                onTap: () async {
                  final city = await pickCity(
                    context,
                    title: 'Leaving from',
                    selected: q.origin,
                  );
                  if (city != null) bloc.add(SearchOriginChanged(city));
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Swap From and To',
                  onPressed: () => bloc.add(const SearchSwapped()),
                  icon: const Icon(Icons.swap_vert),
                  style: IconButton.styleFrom(
                    side: BorderSide(color: palette.border),
                  ),
                ),
              ),
              _FieldLabel('TO'),
              _PickerField(
                icon: Icons.flag_outlined,
                text: q.destination.label,
                semanticsLabel: 'To ${q.destination.label}. Change',
                onTap: () async {
                  final city = await pickCity(
                    context,
                    title: 'Going to',
                    selected: q.destination,
                  );
                  if (city != null) bloc.add(SearchDestinationChanged(city));
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FieldLabel('DEPARTURE'),
                        _PickerField(
                          icon: Icons.calendar_today_outlined,
                          text: Formatters.shortDate(q.date),
                          semanticsLabel:
                              'Departure ${Formatters.shortDate(q.date)}. Change',
                          onTap: () async {
                            final date = await _pickDate(
                              context,
                              initial: q.date,
                              first: DateTime.now(),
                            );
                            if (date != null) bloc.add(SearchDateChanged(date));
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FieldLabel('RETURN · OPTIONAL'),
                        _PickerField(
                          text: q.returnDate == null
                              ? 'Add return'
                              : Formatters.shortDate(q.returnDate!),
                          muted: q.returnDate == null,
                          semanticsLabel: q.returnDate == null
                              ? 'Add a return date'
                              : 'Return ${Formatters.shortDate(q.returnDate!)}. Change',
                          trailing: q.returnDate == null
                              ? null
                              : IconButton(
                                  tooltip: 'Remove return date',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => bloc.add(
                                    const SearchReturnDateChanged(null),
                                  ),
                                ),
                          onTap: () async {
                            final date = await _pickDate(
                              context,
                              initial: q.returnDate ?? q.date,
                              first: q.date,
                            );
                            if (date != null) {
                              bloc.add(SearchReturnDateChanged(date));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CounterRow(
                label: 'Adults',
                value: q.adults,
                min: 1,
                max: SearchQuery.maxPassengers - q.children,
                onChanged: (v) => bloc.add(
                  SearchPassengersChanged(adults: v, children: q.children),
                ),
              ),
              const SizedBox(height: 4),
              _CounterRow(
                label: 'Children',
                value: q.children,
                min: 0,
                max: SearchQuery.maxPassengers - q.adults,
                onChanged: (v) => bloc.add(
                  SearchPassengersChanged(adults: q.adults, children: v),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Search Buses',
                icon: Icons.search,
                onPressed: () => bloc.add(const SearchSubmitted()),
              ),
              if (state.formError != null) ...[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    state.formError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                operators == 0
                    ? 'Verified operators · Live seats · Upfront fares'
                    : '$operators verified operators · Live seats · Upfront fares',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.link),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<DateTime?> _pickDate(
    BuildContext context, {
    required DateTime initial,
    required DateTime first,
  }) {
    final firstDay = SearchQuery.dayOf(first);
    final start = initial.isBefore(firstDay) ? firstDay : initial;
    return showDatePicker(
      context: context,
      initialDate: start,
      firstDate: firstDay,
      lastDate: firstDay.add(const Duration(days: 90)),
    );
  }
}

class _BookAgain extends StatelessWidget {
  const _BookAgain();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return BlocBuilder<SearchBloc, SearchState>(
      buildWhen: (a, b) => a.recentRoutes != b.recentRoutes,
      builder: (context, state) {
        final recent = state.recentRoutes.isNotEmpty;
        final routes = recent
            ? state.recentRoutes
            : SearchHomePage.popularRoutes;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeading(recent ? 'Book again' : 'Popular routes'),
            for (final route in routes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  onTap: () => context.read<SearchBloc>()
                    ..add(SearchRecentSelected(route))
                    ..add(const SearchSubmitted()),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: palette.iconTile,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          recent ? Icons.history : Icons.trending_up,
                          size: 19,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${route.origin.name} → ${route.destination.name}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: palette.text,
                              ),
                            ),
                            Text(
                              recent
                                  ? 'Searched recently · Tap to search again'
                                  : '${route.origin.country} → ${route.destination.country}',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: palette.muted),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ExcludeSemantics(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
            color: AppPalette.of(context).muted,
          ),
        ),
      ),
    );
  }
}

/// Looks like a text field, opens a picker when tapped.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.text,
    required this.onTap,
    required this.semanticsLabel,
    this.icon,
    this.muted = false,
    this.trailing,
  });

  final String text;
  final VoidCallback onTap;
  final String semanticsLabel;
  final IconData? icon;
  final bool muted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: trailing == null,
      child: Material(
        color: palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: palette.border),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: trailing == null ? 14 : 2,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: palette.muted),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: muted ? palette.muted : palette.text,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final style = IconButton.styleFrom(side: BorderSide(color: palette.border));
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: palette.text)),
        ),
        IconButton(
          tooltip: 'Fewer ${label.toLowerCase()}',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove, size: 18),
          style: style,
        ),
        SizedBox(
          width: 32,
          child: Semantics(
            label: '$value ${label.toLowerCase()}',
            liveRegion: true,
            excludeSemantics: true,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'More ${label.toLowerCase()}',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add, size: 18),
          style: style,
        ),
      ],
    );
  }
}

/// Bottom sheet listing the cities BookMe serves.
Future<City?> pickCity(
  BuildContext context, {
  required String title,
  required City selected,
}) {
  return showModalBottomSheet<City>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final palette = AppPalette.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
            ),
            for (final city in Cities.all)
              ListTile(
                leading: Icon(
                  city == selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: city == selected ? palette.link : palette.muted,
                ),
                title: Text(city.name),
                subtitle: Text('${city.station} · ${city.country}'),
                selected: city == selected,
                onTap: () => Navigator.of(sheetContext).pop(city),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
