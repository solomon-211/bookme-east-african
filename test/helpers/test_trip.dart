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

/// [testTrip] (18,500 RWF in total) on another day and at another price.
TripSummary otherDeparture(
  String id, {
  required DateTime departure,
  int baseFare = 18000,
  String toStation = 'Namirembe',
  String toCode = 'KLA',
}) => TripSummary(
  tripId: id,
  operatorName: testTrip.operatorName,
  fromCode: testTrip.fromCode,
  fromStation: testTrip.fromStation,
  toCode: toCode,
  toStation: toStation,
  departure: departure,
  arrival: departure.add(const Duration(hours: 9, minutes: 30)),
  durationLabel: testTrip.durationLabel,
  baseFare: baseFare,
  serviceFee: testTrip.serviceFee,
);
