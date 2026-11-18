import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TripStatus {
  static const scheduled = 'scheduled';
  static const delayed = 'delayed';
  static const cancelled = 'cancelled';
}

/// Firestore: trips/{tripId}. One scheduled departure of a route.
///
/// `origin`, `destination` and `operatorName` are denormalized copies so
/// search results need no joins (Firestore has none).
class Trip extends Equatable {
  const Trip({
    required this.id,
    required this.routeId,
    required this.operatorId,
    required this.operatorName,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.currency,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.status,
  });

  final String id;
  final String routeId; // FK -> routes
  final String operatorId; // FK -> operators
  final String operatorName;
  final String origin;
  final String destination;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int price;
  final String currency;
  final int seatsTotal;
  final int seatsAvailable;
  final String status;

  bool get isFull => seatsAvailable <= 0;
  bool get isBookable =>
      status != TripStatus.cancelled &&
      !isFull &&
      departureTime.isAfter(DateTime.now());

  factory Trip.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Trip(
      id: doc.id,
      routeId: d['routeId'] as String,
      operatorId: d['operatorId'] as String,
      operatorName: d['operatorName'] as String,
      origin: d['origin'] as String,
      destination: d['destination'] as String,
      departureTime: (d['departureTime'] as Timestamp).toDate(),
      arrivalTime: (d['arrivalTime'] as Timestamp).toDate(),
      price: (d['price'] as num).toInt(),
      currency: d['currency'] as String,
      seatsTotal: (d['seatsTotal'] as num).toInt(),
      seatsAvailable: (d['seatsAvailable'] as num).toInt(),
      status: (d['status'] ?? TripStatus.scheduled) as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'routeId': routeId,
        'operatorId': operatorId,
        'operatorName': operatorName,
        'origin': origin,
        'destination': destination,
        'departureTime': Timestamp.fromDate(departureTime),
        'arrivalTime': Timestamp.fromDate(arrivalTime),
        'price': price,
        'currency': currency,
        'seatsTotal': seatsTotal,
        'seatsAvailable': seatsAvailable,
        'status': status,
      };

  @override
  List<Object?> get props => [
        id, routeId, operatorId, departureTime, price,
        seatsAvailable, status,
      ];
}
