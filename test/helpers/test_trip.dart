import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';

final TripSummary testTrip = TripSummary(
  tripId: 'trip-1',
  operatorName: 'Trinity Express',
  fromCode: 'KGL',
  fromStation: 'Nyabugogo',
  toCode: 'KLA',
  toStation: 'Namirembe',
  departure: DateTime(2026, 12, 4, 21),
  arrival: DateTime(2026, 12, 5, 6, 30),
  durationLabel: '9h 30m',
  baseFare: 18000,
  serviceFee: 500,
);
