import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/core/theme/app_palette.dart';
import 'package:bookme_summative_project/core/utils/formatters.dart';
import 'package:bookme_summative_project/core/widgets/page_header.dart';
import 'package:bookme_summative_project/core/widgets/surface_card.dart';
import 'package:bookme_summative_project/features/booking/presentation/widgets/primary_button.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/search_repository.dart';
import 'package:bookme_summative_project/features/search/presentation/bloc/search_bloc.dart';
import 'package:bookme_summative_project/features/search/presentation/pages/waitlist_dialog.dart';
import 'package:bookme_summative_project/features/search/presentation/search_navigation.dart';
import 'package:bookme_summative_project/features/search/presentation/widgets/trip_result_card.dart';
import 'package:bookme_summative_project/features/search/presentation/widgets/trip_times_row.dart';

/// Screen 4: one bus — stops, amenities and the full price.
///
/// Re-reads the trip when it opens so the seat count is live, then hands
/// over to Booking & Payment.
class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({required this.trip, super.key});

  final BusTrip trip;

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  late BusTrip _trip = widget.trip;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await context.read<SearchRepository>().tripById(_trip.id);
      if (fresh != null && mounted) setState(() => _trip = fresh);
    } on SearchFailure {
      // Keep the copy from the results; booking re-checks seats anyway.
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final trip = _trip;
    final query = context.select((SearchBloc b) => b.state.query);
    final travellers = query.passengers;
    final bookable = trip.isBookable(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: trip.operatorName,
              subtitle: [
                if (trip.operatorRating > 0)
                  '${trip.operatorRating.toStringAsFixed(1)} ★ safety rating',
                trip.serviceClass,
                if (trip.operatorVerified) 'Verified partner',
              ].join(' · '),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (trip.operatorVerified)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: StatusPill(
                        icon: Icons.verified_user_outlined,
                        label: 'Verified operator',
                      ),
                    ),
                  const SizedBox(height: 12),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TripTimesRow(trip: trip),
                        const SizedBox(height: 8),
                        Text(
                          '${Formatters.shortDate(trip.departure)} → '
                          '${Formatters.shortDate(trip.arrival)} · ${trip.operatorName}',
                          style: TextStyle(fontSize: 12, color: palette.muted),
                        ),
                        Divider(height: 28, color: palette.border),
                        _Stop(
                          name: '${trip.fromStation}, ${trip.origin}',
                          time: Formatters.time(trip.departure),
                          note: 'Boarding · Arrive 30 minutes early',
                        ),
                        for (final s in trip.stops)
                          _Stop(
                            name: s.name,
                            time: '~${Formatters.time(s.time)}',
                            note: s.note,
                          ),
                        _Stop(
                          name: '${trip.toStation}, ${trip.destination}',
                          time: Formatters.time(trip.arrival),
                          note:
                              'Drop-off · ${Formatters.shortDate(trip.arrival)}',
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (trip.amenities.isNotEmpty) ...[
                    const SectionHeading('On board'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in Amenity.values)
                          if (trip.hasAmenity(a)) AmenityChip(amenity: a),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SectionHeading('What you\'ll pay'),
                  SurfaceCard(
                    child: Column(
                      children: [
                        _PriceRow('Base fare', trip.price, trip.currency),
                        _PriceRow('Taxes', trip.taxes, trip.currency),
                        _PriceRow(
                          'BookMe service fee',
                          trip.serviceFee,
                          trip.currency,
                        ),
                        Divider(height: 20, color: palette.border),
                        _PriceRow(
                          'Total per seat',
                          trip.total,
                          trip.currency,
                          bold: true,
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No hidden fees at the counter',
                            style: TextStyle(fontSize: 12, color: palette.link),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '100% refund for delays over 2 hours or cancellations. '
                    'Border and arrival times are estimates.',
                    style: TextStyle(fontSize: 12, color: palette.link),
                  ),
                  if (travellers > 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Each seat is booked and paid separately: you\'ll book '
                      'one seat now, then the next from these results.',
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: palette.card,
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total · 1 seat${travellers > 1 ? ' of $travellers' : ''}',
                          style: TextStyle(color: palette.muted),
                        ),
                      ),
                      Text(
                        Formatters.money(trip.total, trip.currency),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (bookable)
                    PrimaryButton(
                      label: 'Continue to Payment',
                      icon: Icons.arrow_forward,
                      onPressed: () => context
                          .read<SearchNavigation>()
                          .startBooking(context, trip),
                    )
                  else if (trip.isFull)
                    PrimaryButton(
                      label: 'Notify me if a seat opens',
                      icon: Icons.notifications_none,
                      style: PrimaryButtonStyle.outlined,
                      onPressed: () => showWaitlistDialog(context, trip),
                    )
                  else
                    const PrimaryButton(
                      label: 'This bus can no longer be booked',
                      onPressed: null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.name,
    required this.time,
    required this.note,
    this.last = false,
  });

  final String name;
  final String time;
  final String note;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: palette.text,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: VerticalDivider(width: 2, color: palette.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  Text(
                    note,
                    style: TextStyle(fontSize: 12, color: palette.muted),
                  ),
                ],
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(fontWeight: FontWeight.w600, color: palette.text),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.amount, this.currency, {this.bold = false});

  final String label;
  final int amount;
  final String currency;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final weight = bold ? FontWeight.w800 : FontWeight.w500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? palette.text : palette.muted,
                fontWeight: weight,
              ),
            ),
          ),
          Text(
            Formatters.money(amount, currency),
            style: TextStyle(color: palette.text, fontWeight: weight),
          ),
        ],
      ),
    );
  }
}
