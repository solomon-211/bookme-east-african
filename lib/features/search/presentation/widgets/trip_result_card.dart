import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/core/widgets/surface_card.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/presentation/widgets/search_format.dart';
import 'package:bookme_summative_project/features/search/presentation/widgets/trip_times_row.dart';

/// One bus in the results list.
///
/// Fully booked buses are faded and offer the waitlist instead of opening.
class TripResultCard extends StatelessWidget {
  const TripResultCard({
    required this.trip,
    required this.onTap,
    required this.onNotify,
    required this.onLeaveWaitlist,
    this.onWaitlist = false,
    this.busy = false,
    super.key,
  });

  final BusTrip trip;
  final VoidCallback onTap;
  final VoidCallback onNotify;
  final VoidCallback onLeaveWaitlist;

  /// The traveller already asked to be told about this bus.
  final bool onWaitlist;

  /// A waitlist join/leave for this bus is in progress.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final full = trip.isFull;
    final seatsColor = full
        ? palette.muted
        : trip.isAlmostFull
        ? palette.warningIcon
        : palette.link;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OperatorAvatar(name: trip.operatorName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.operatorName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: palette.text,
                    ),
                  ),
                  Text(
                    SearchFormat.classLine(trip),
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                ],
              ),
            ),
            if (trip.operatorVerified)
              Tooltip(
                message: 'Verified operator',
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 20,
                  color: palette.link,
                  semanticLabel: 'Verified operator',
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TripTimesRow(trip: trip),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                SearchFormat.seatsLeft(trip),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: seatsColor,
                ),
              ),
            ),
            Text(
              Formatters.money(trip.total, trip.currency),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ],
        ),
      ],
    );

    if (!full) {
      return SurfaceCard(
        onTap: onTap,
        child: Semantics(
          button: true,
          hint: 'Opens trip details',
          child: details,
        ),
      );
    }

    return SurfaceCard(
      color: palette.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Opacity(opacity: 0.55, child: details),
          const SizedBox(height: 14),
          if (onWaitlist)
            _OnWaitlistBar(busy: busy, onLeave: onLeaveWaitlist)
          else
            OutlinedButton.icon(
              onPressed: busy ? null : onNotify,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_none, size: 18),
              label: const Text('Notify me if a seat opens'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: palette.text,
                backgroundColor: palette.card,
                side: BorderSide(color: palette.border),
                shape: const StadiumBorder(),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnWaitlistBar extends StatelessWidget {
  const _OnWaitlistBar({required this.busy, required this.onLeave});

  final bool busy;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        color: palette.successSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active, size: 18, color: palette.link),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re on the waitlist',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: palette.text,
              ),
            ),
          ),
          TextButton(
            onPressed: busy ? null : onLeave,
            child: busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

/// Square with the operator's first letter, as in the design.
class OperatorAvatar extends StatelessWidget {
  const OperatorAvatar({required this.name, this.size = 36, super.key});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.iconTile,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: size * 0.42,
            color: palette.text,
          ),
        ),
      ),
    );
  }
}

/// Small rounded label, e.g. `✓ Verified operator`.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.successSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.link),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.link,
            ),
          ),
        ],
      ),
    );
  }
}

/// Outlined chip with an amenity icon, e.g. `Wi-Fi`.
class AmenityChip extends StatelessWidget {
  const AmenityChip({required this.amenity, super.key});

  final Amenity amenity;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            SearchFormat.amenityIcon(amenity),
            size: 15,
            color: palette.text,
          ),
          const SizedBox(width: 6),
          Text(
            amenity.label,
            style: TextStyle(fontSize: 13, color: palette.text),
          ),
        ],
      ),
    );
  }
}
