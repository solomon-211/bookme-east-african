import 'package:equatable/equatable.dart';

/// A read-only snapshot of the trip the traveller picked on Trip Details.
///
/// The Search feature builds this from the `trips/{tripId}` document and
/// passes it into the booking flow, so the booking screens never re-query
/// the trip. Prices are whole numbers in the trip's [currency] (RWF has no
/// minor unit, so we never use doubles for money).
class TripSummary extends Equatable {
  const TripSummary({
    required this.tripId,
    required this.operatorName,
    required this.fromCode,
    required this.fromStation,
    required this.toCode,
    required this.toStation,
    required this.departure,
    required this.arrival,
    required this.durationLabel,
    required this.baseFare,
    this.taxes = 0,
    this.serviceFee = 0,
    this.currency = 'RWF',
  });

  final String tripId;
  final String operatorName;

  /// Short city code shown in large type, e.g. `KGL`.
  final String fromCode;

  /// Boarding point, e.g. `Nyabugogo`.
  final String fromStation;
  final String toCode;
  final String toStation;
  final DateTime departure;
  final DateTime arrival;

  /// Pre-formatted journey length, e.g. `9h 30m`.
  final String durationLabel;
  final int baseFare;
  final int taxes;
  final int serviceFee;
  final String currency;

  /// What the traveller pays. There are no hidden fees: this is the only
  /// total the app ever shows or charges.
  int get total => baseFare + taxes + serviceFee;

  @override
  List<Object?> get props => [
    tripId,
    operatorName,
    fromCode,
    fromStation,
    toCode,
    toStation,
    departure,
    arrival,
    durationLabel,
    baseFare,
    taxes,
    serviceFee,
    currency,
  ];
}
