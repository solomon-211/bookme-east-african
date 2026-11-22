import 'package:equatable/equatable.dart';

/// Firestore: `waitlist/{userId}_{tripId}`. A request to be told by SMS when
/// a seat opens on a fully booked bus. Joining does not reserve a seat.
///
/// Route and time are copied from the trip so the entry can be shown
/// (and the SMS written) without reading the trip again.
class WaitlistEntry extends Equatable {
  const WaitlistEntry({
    required this.id,
    required this.userId,
    required this.tripId,
    required this.phone,
    required this.origin,
    required this.destination,
    required this.operatorName,
    required this.departure,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String tripId;

  /// E.164, e.g. `+250781234412`.
  final String phone;
  final String origin;
  final String destination;
  final String operatorName;
  final DateTime departure;
  final DateTime? createdAt;

  /// One entry per traveller per trip, so the id is predictable and a
  /// double tap can't create two entries.
  static String idFor(String userId, String tripId) => '${userId}_$tripId';

  @override
  List<Object?> get props => [
    id,
    userId,
    tripId,
    phone,
    origin,
    destination,
    operatorName,
    departure,
    createdAt,
  ];
}
