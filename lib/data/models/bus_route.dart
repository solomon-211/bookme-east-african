import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore: routes/{routeId}. An operator's origin -> destination corridor.
class BusRoute extends Equatable {
  const BusRoute({
    required this.id,
    required this.operatorId,
    required this.origin,
    required this.destination,
    required this.originCountry,
    required this.destinationCountry,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final String id;
  final String operatorId; // FK -> operators
  final String origin;
  final String destination;
  final String originCountry;
  final String destinationCountry;
  final int distanceKm;
  final int durationMinutes;

  bool get isCrossBorder => originCountry != destinationCountry;

  factory BusRoute.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BusRoute(
      id: doc.id,
      operatorId: d['operatorId'] as String,
      origin: d['origin'] as String,
      destination: d['destination'] as String,
      originCountry: d['originCountry'] as String,
      destinationCountry: d['destinationCountry'] as String,
      distanceKm: (d['distanceKm'] as num).toInt(),
      durationMinutes: (d['durationMinutes'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'operatorId': operatorId,
        'origin': origin,
        'destination': destination,
        'originCountry': originCountry,
        'destinationCountry': destinationCountry,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
      };

  @override
  List<Object?> get props => [id, operatorId, origin, destination];
}
