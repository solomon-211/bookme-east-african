import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';

/// `21:00  ○──🚌──●  06:30` with the stations underneath.
///
/// Shared by My Trips, the digital ticket, Ready for Journey and Manage
/// Booking, which all show the same row in the design.
class TripRouteRow extends StatelessWidget {
  const TripRouteRow({required this.trip, this.dark = false, super.key});

  final TripSummary trip;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final timeStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: dark ? Colors.white : context.palette.text,
    );
    final placeStyle = TextStyle(fontSize: 10, color: context.palette.muted);

    return Row(
      children: [
        Expanded(
          child: _Stop(
            time: Formatters.time(trip.departure),
            place: '${trip.fromCode} · ${trip.fromStation}',
            timeStyle: timeStyle,
            placeStyle: placeStyle,
          ),
        ),
        _JourneyLine(label: trip.durationLabel, dark: dark),
        Expanded(
          child: _Stop(
            time: Formatters.time(trip.arrival),
            place: '${trip.toCode} · ${trip.toStation}',
            timeStyle: timeStyle,
            placeStyle: placeStyle,
            alignEnd: true,
          ),
        ),
      ],
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
  final TextStyle timeStyle;
  final TextStyle placeStyle;
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
        const SizedBox(height: 2),
        Text(
          place,
          style: placeStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        ),
      ],
    );
  }
}

/// Hollow dot, line, bus, line, filled dot, with the journey length above.
class _JourneyLine extends StatelessWidget {
  const _JourneyLine({required this.label, required this.dark});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final lineColor = dark ? Colors.white : context.palette.text;
    final accent = dark ? AppColors.lime : AppColors.success;
    final line = Expanded(child: Container(height: 1, color: lineColor));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: context.palette.muted),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: lineColor),
                  ),
                ),
                line,
                Icon(Icons.directions_bus_rounded, size: 14, color: accent),
                line,
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lineColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
