import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookme_summative_project/features/tickets/data/models/trip_document_mapper.dart';

void main() {
  final departure = DateTime(2026, 12, 4, 21);
  final arrival = DateTime(2026, 12, 5, 6, 30);

  test('reads a trip written in the booking style', () {
    final trip = TripDocumentMapper.fromMap('trip-1', {
      'operatorName': 'Trinity Express',
      'fromCode': 'KGL',
      'fromStation': 'Nyabugogo',
      'toCode': 'KLA',
      'toStation': 'Namirembe',
      'departure': Timestamp.fromDate(departure),
      'arrival': Timestamp.fromDate(arrival),
      'durationLabel': '9h 30m',
      'baseFare': 18000,
      'taxes': 200,
      'serviceFee': 500,
      'currency': 'RWF',
    })!;

    expect(trip.tripId, 'trip-1');
    expect(trip.operatorName, 'Trinity Express');
    expect(trip.fromCode, 'KGL');
    expect(trip.toStation, 'Namirembe');
    expect(trip.departure, departure);
    expect(trip.arrival, arrival);
    expect(trip.total, 18700);
  });

  test('reads a trip written in the search style and fills the gaps', () {
    final trip = TripDocumentMapper.fromMap('trip-2', {
      'origin': 'Kigali',
      'destination': 'Nairobi - Machakos',
      'departureTime': Timestamp.fromDate(departure),
      'arrivalTime': Timestamp.fromDate(
        departure.add(const Duration(hours: 22)),
      ),
      'price': 30000.0,
    })!;

    expect(trip.fromCode, 'KGL');
    expect(trip.toCode, 'NBO');
    expect(trip.fromStation, 'Kigali');
    expect(trip.durationLabel, '22h');
    expect(trip.baseFare, 30000);
    expect(trip.serviceFee, 0);
    expect(trip.currency, 'RWF');
    expect(trip.operatorName, 'BookMe partner');
  });

  test('a document missing a required field is skipped', () {
    expect(
      TripDocumentMapper.fromMap('trip-3', {
        'origin': 'Kigali',
        'destination': 'Kampala',
        'departureTime': Timestamp.fromDate(departure),
        // No arrival time.
        'price': 18000,
      }),
      isNull,
    );
    expect(
      TripDocumentMapper.fromMap('trip-4', {
        'origin': '  ',
        'destination': 'Kampala',
        'departureTime': Timestamp.fromDate(departure),
        'arrivalTime': Timestamp.fromDate(arrival),
        'price': 18000,
      }),
      isNull,
    );
  });

  test('city codes for known and unknown cities', () {
    expect(TripDocumentMapper.cityCode('Dar es Salaam'), 'DAR');
    expect(TripDocumentMapper.cityCode('Kampala, Namirembe'), 'KLA');
    expect(TripDocumentMapper.cityCode('Musanze'), 'MUS');
    expect(TripDocumentMapper.cityCode('Hu'), 'HU');
  });

  test('duration labels', () {
    expect(
      TripDocumentMapper.durationLabel(const Duration(hours: 9, minutes: 30)),
      '9h 30m',
    );
    expect(TripDocumentMapper.durationLabel(const Duration(hours: 4)), '4h');
    expect(
      TripDocumentMapper.durationLabel(const Duration(minutes: 45)),
      '45m',
    );
  });
}
