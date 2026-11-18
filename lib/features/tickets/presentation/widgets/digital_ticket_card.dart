import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:bookme_summative_project/core/theme/app_colors.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/trip_route_row.dart';
import 'package:bookme_summative_project/features/tickets/presentation/widgets/upcoming_trip_card.dart';

/// The white ticket with the route, passenger and boarding QR code.
///
/// Everything on it comes from the [Ticket], so it renders the same from
/// the live booking or from the copy saved on the phone.
class DigitalTicketCard extends StatelessWidget {
  const DigitalTicketCard({required this.ticket, super.key});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final trip = ticket.trip;
    final booking = ticket.booking;
    final passenger = booking.passenger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${trip.fromCode} → ${trip.toCode}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const _OfflineChip(),
            ],
          ),
          const SizedBox(height: 12),
          TripRouteRow(trip: trip),
          const SizedBox(height: 8),
          Text(
            '${Formatters.shortDate(trip.departure)} → '
            '${Formatters.shortDate(trip.arrival)} · '
            '${trip.operatorName} · Seat ${booking.seatNumber}',
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Passenger',
            value: passenger?.fullName ?? 'Not added',
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Boarding',
            value: Formatters.time(trip.departure.subtract(kBoardingWindow)),
          ),
          const SizedBox(height: 12),
          if (ticket.isCancelled)
            const _CancelledNotice()
          else
            _BoardingCode(ticket: ticket),
        ],
      ),
    );
  }
}

class _OfflineChip extends StatelessWidget {
  const _OfflineChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.ink),
          SizedBox(width: 5),
          Text(
            'Works Offline',
            style: TextStyle(
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _BoardingCode extends StatelessWidget {
  const _BoardingCode({required this.ticket});

  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final reference = ticket.booking.reference;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            label: 'Boarding QR code for booking $reference',
            image: true,
            child: QrImageView(
              data: ticket.qrPayload,
              size: 158,
              padding: EdgeInsets.zero,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          reference,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
        const SizedBox(height: 5),
        const Text(
          'Show this code at boarding',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, height: 1.4, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _CancelledNotice extends StatelessWidget {
  const _CancelledNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.block_rounded, size: 18, color: AppColors.error),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This booking was cancelled. The ticket can no longer be '
              'used to board.',
              style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
