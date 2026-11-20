import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/trip_route_row.dart';

/// How long before departure the operator starts boarding.
const Duration kBoardingWindow = Duration(minutes: 30);

/// The dark card at the top of My Trips for the next trip.
class UpcomingTripCard extends StatelessWidget {
  const UpcomingTripCard({
    required this.ticket,
    required this.onShowQr,
    required this.onManage,
    super.key,
  });

  final Ticket ticket;
  final VoidCallback onShowQr;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final trip = ticket.trip;
    final boarding = trip.departure.subtract(kBoardingWindow);
    final weekday = Formatters.shortDate(boarding).split(' ').first;
    const softStyle = TextStyle(
      fontSize: 11,
      height: 1.4,
      color: Color(0xFF969FA2),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Boarding opens $weekday at ${Formatters.time(boarding)}',
                  style: softStyle,
                ),
              ),
              TripStatusChip(status: ticket.tripStatus),
            ],
          ),
          const SizedBox(height: 12),
          TripRouteRow(trip: trip, dark: true),
          const SizedBox(height: 8),
          Text(
            '${Formatters.shortDate(trip.departure)} → '
            '${Formatters.shortDate(trip.arrival)} · '
            '${trip.operatorName} · Seat ${ticket.booking.seatNumber}',
            style: softStyle,
          ),
          const SizedBox(height: 12),
          Text(
            'Confirmed · Not yet boarded · ${ticket.booking.reference}',
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.lime,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PillButton(
                  label: 'Show Offline QR',
                  icon: Icons.qr_code_2_rounded,
                  onPressed: onShowQr,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PillButton(label: 'Manage', onPressed: onManage),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// White pill showing whether the departure is on time.
class TripStatusChip extends StatelessWidget {
  const TripStatusChip({required this.status, super.key});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TripStatus.scheduled => ('On schedule', AppColors.ink),
      TripStatus.delayed => ('Delayed', AppColors.warningText),
      TripStatus.cancelled => ('Cancelled by operator', AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
        ],
      ),
    );
  }
}
