import 'package:flutter/material.dart';

import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/border_crossing.dart';

/// One row in "Recent past trips": `Kampala → Kigali`,
/// `Trinity Express · 12 Sep · Completed`.
class PastTripTile extends StatelessWidget {
  const PastTripTile({required this.ticket, required this.onTap, super.key});

  final Ticket ticket;
  final VoidCallback onTap;

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final trip = ticket.trip;
    final date = '${trip.departure.day} ${_months[trip.departure.month - 1]}';
    final outcome = ticket.isCancelled ? 'Cancelled' : 'Completed';

    return Material(
      color: context.palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.palette.iconTile,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  ticket.isCancelled
                      ? Icons.cancel_outlined
                      : Icons.check_circle_outline,
                  size: 18,
                  color: context.palette.text,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cityName(trip.fromCode, station: trip.fromStation)} → '
                      '${cityName(trip.toCode, station: trip.toStation)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: context.palette.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${trip.operatorName} · $date · $outcome',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: context.palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 16, color: context.palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}
