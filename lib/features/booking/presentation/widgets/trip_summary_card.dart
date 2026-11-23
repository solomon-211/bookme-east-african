import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';

/// Departure → arrival card used on every booking screen.
///
/// The dark version is used during checkout, the light one on the receipt.
class TripSummaryCard extends StatelessWidget {
  const TripSummaryCard({
    required this.trip,
    this.seatNumber,
    this.footer,
    this.dark = true,
    super.key,
  });

  final TripSummary trip;
  final String? seatNumber;

  /// Extra content under a divider, e.g. the total to pay.
  final Widget? footer;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : context.palette.text;
    final soft = dark ? Colors.white70 : context.palette.muted;
    final textTheme = Theme.of(context).textTheme;
    final timeStyle = textTheme.headlineSmall?.copyWith(
      color: fg,
      fontWeight: FontWeight.w800,
    );
    final smallStyle = textTheme.bodySmall?.copyWith(color: soft);
    final seat = seatNumber == null ? '' : ' · Seat $seatNumber';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.ink : context.palette.card,
        borderRadius: BorderRadius.circular(16),
        border: dark ? null : Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stop(
                  time: Formatters.time(trip.departure),
                  place: '${trip.fromCode} · ${trip.fromStation}',
                  timeStyle: timeStyle,
                  placeStyle: smallStyle,
                ),
              ),
              _JourneyLine(
                label: trip.durationLabel,
                color: soft,
                accent: dark ? AppColors.lime : AppColors.success,
              ),
              Expanded(
                child: _Stop(
                  time: Formatters.time(trip.arrival),
                  place: '${trip.toCode} · ${trip.toStation}',
                  timeStyle: timeStyle,
                  placeStyle: smallStyle,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${Formatters.shortDate(trip.departure)} → '
            '${Formatters.shortDate(trip.arrival)} · '
            '${trip.operatorName}$seat',
            style: smallStyle,
          ),
          if (footer != null) ...[
            Divider(height: 24, color: soft.withValues(alpha: 0.3)),
            DefaultTextStyle.merge(
              style: TextStyle(color: fg),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.time,
    required this.place,
    required this.timeStyle,
    required this.placeStyle,
    this.alignEnd = false,
  });

  final String time;
  final String place;
  final TextStyle? timeStyle;
  final TextStyle? placeStyle;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(time, style: timeStyle),
        ),
        Text(
          place,
          style: placeStyle,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Dot, line, bus icon, line, dot, with the journey length above it.
class _JourneyLine extends StatelessWidget {
  const _JourneyLine({
    required this.label,
    required this.color,
    required this.accent,
  });

  final String label;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    final line = Expanded(child: Container(height: 1, color: color));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                dot,
                line,
                Icon(Icons.directions_bus_rounded, size: 16, color: accent),
                line,
                dot,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
