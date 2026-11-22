import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';

/// `21:00 ── 9h 30m 🚌 ── 06:30` with the stations underneath.
class TripTimesRow extends StatelessWidget {
  const TripTimesRow({required this.trip, this.large = true, super.key});

  final BusTrip trip;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final timeStyle = TextStyle(
      fontSize: large ? 26 : 20,
      fontWeight: FontWeight.w800,
      color: palette.text,
      height: 1.1,
    );
    final placeStyle = TextStyle(fontSize: 12, color: palette.muted);

    return Semantics(
      label:
          'Leaves ${trip.fromStation} at ${Formatters.time(trip.departure)}, '
          'arrives ${trip.toStation} at ${Formatters.time(trip.arrival)}'
          '${trip.isOvernight ? ' the next day' : ''}, '
          '${BusTrip.durationLabel(trip.duration)}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Formatters.time(trip.departure), style: timeStyle),
                const SizedBox(height: 4),
                Text(
                  '${trip.fromCode} · ${trip.fromStation}',
                  style: placeStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: JourneyLine(label: BusTrip.durationLabel(trip.duration)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Formatters.time(trip.arrival), style: timeStyle),
                    if (trip.isOvernight)
                      Text(
                        '+1',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${trip.toCode} · ${trip.toStation}',
                  style: placeStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dotted line with the journey length and a bus in the middle.
class JourneyLine extends StatelessWidget {
  const JourneyLine({required this.label, this.width = 96, super.key});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: palette.muted)),
          const SizedBox(height: 4),
          Row(
            children: [
              _dot(palette.text),
              Expanded(child: Divider(color: palette.border, thickness: 1.2)),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.lime : AppColors.limeSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.directions_bus_filled,
                  size: 13,
                  color: AppColors.ink,
                ),
              ),
              Expanded(child: Divider(color: palette.border, thickness: 1.2)),
              _dot(palette.text),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
