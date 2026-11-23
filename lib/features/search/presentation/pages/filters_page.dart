import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/core/widgets/choice_pill.dart';
import 'package:bookme_summative_project/core/widgets/page_header.dart';
import 'package:bookme_summative_project/core/widgets/surface_card.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/entities/trip_filter.dart';
import 'package:bookme_summative_project/features/search/presentation/bloc/search_bloc.dart';
import 'package:bookme_summative_project/features/search/presentation/widgets/search_format.dart';

/// Screen 3: "Find your bus". Edits a draft filter and returns it with
/// `Navigator.pop`; nothing changes on the results until "Show N Buses".
class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key});

  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  late TripFilter _draft = context.read<SearchBloc>().state.filter;

  void _set(TripFilter next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final state = context.watch<SearchBloc>().state;
    final q = state.query;
    final matches = _draft.apply(state.dayTrips, now: state.asOf).length;
    final options = state.operatorOptions;
    final range = state.priceRange;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Find your bus',
              subtitle:
                  '${q.origin.name} → ${q.destination.name} · ${Formatters.shortDate(state.selectedDay)}',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SectionHeading('Departure time'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final w in DepartureWindow.values)
                        ChoicePill(
                          label: w.label,
                          selected: _draft.window == w,
                          onTap: () => _set(_draft.copyWith(window: w)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SectionHeading('Price per adult'),
                  SurfaceCard(
                    child: _priceSection(range, state.currency, palette),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeading('Operator'),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        for (final o in options)
                          CheckboxListTile(
                            value:
                                _draft.operatorIds.isEmpty ||
                                _draft.operatorIds.contains(o.id),
                            title: Text(o.name),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (_) => _toggleOperator(o.id, options),
                          ),
                        if (options.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No operators on this route.',
                              style: TextStyle(color: palette.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeading('Amenities'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in Amenity.values)
                        FilterChip(
                          avatar: Icon(SearchFormat.amenityIcon(a), size: 16),
                          label: Text(a.label),
                          selected: _draft.amenities.contains(a),
                          onSelected: (_) => _set(_draft.toggleAmenity(a)),
                          shape: const StadiumBorder(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  PrimaryButton(
                    label: matches == 0
                        ? 'No buses match'
                        : 'Show $matches Bus${matches == 1 ? '' : 'es'}',
                    onPressed: matches == 0
                        ? null
                        : () => Navigator.of(context).pop(_draft),
                  ),
                  TextButton(
                    onPressed: () => _set(TripFilter.none),
                    child: const Text('Reset filters'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceSection(PriceRange? range, String currency, AppPalette palette) {
    if (range == null) {
      return Text(
        'No prices to filter.',
        style: TextStyle(color: palette.muted),
      );
    }
    final low = (_draft.minPrice ?? range.min).clamp(range.min, range.max);
    final high = (_draft.maxPrice ?? range.max).clamp(range.min, range.max);
    Widget row(String label, int value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: palette.muted)),
          ),
          Text(
            Formatters.money(value, currency),
            style: TextStyle(fontWeight: FontWeight.w700, color: palette.text),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row('Minimum', low),
        row('Maximum', high),
        if (range.max > range.min)
          RangeSlider(
            min: range.min.toDouble(),
            max: range.max.toDouble(),
            values: RangeValues(low.toDouble(), high.toDouble()),
            labels: RangeLabels(
              Formatters.money(low, currency),
              Formatters.money(high, currency),
            ),
            onChanged: (v) {
              final min = v.start.round();
              final max = v.end.round();
              _set(
                min <= range.min && max >= range.max
                    ? _draft.copyWith(clearPrice: true)
                    : _draft.copyWith(minPrice: min, maxPrice: max),
              );
            },
          ),
        Text(
          'Includes taxes and service fees',
          style: TextStyle(fontSize: 12, color: palette.link),
        ),
      ],
    );
  }

  /// An empty set means "every operator", so unchecking the last one is
  /// refused instead of silently meaning "all".
  void _toggleOperator(String id, List<OperatorOption> options) {
    final all = {for (final o in options) o.id};
    final current = _draft.operatorIds.isEmpty
        ? {...all}
        : {..._draft.operatorIds};
    if (!current.remove(id)) current.add(id);
    if (current.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Keep at least one operator.')),
        );
      return;
    }
    _set(
      _draft.copyWith(operatorIds: current.length == all.length ? {} : current),
    );
  }
}
