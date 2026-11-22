import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/search/domain/entities/waitlist_entry.dart';

/// Converts `waitlist/{entryId}` documents to and from [WaitlistEntry].
class WaitlistEntryModel {
  const WaitlistEntryModel._();

  static WaitlistEntry? fromMap(String id, Map<String, dynamic> map) {
    final departure = map['departureTime'];
    if (departure is! Timestamp) return null;
    final createdAt = map['createdAt'];
    return WaitlistEntry(
      id: id,
      userId: (map['userId'] ?? '') as String,
      tripId: (map['tripId'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      origin: (map['origin'] ?? '') as String,
      destination: (map['destination'] ?? '') as String,
      operatorName: (map['operatorName'] ?? '') as String,
      departure: departure.toDate(),
      // Null for a moment after a write, until the server fills it in.
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  /// Body for a new entry. `createdAt` is set by the server, and the
  /// security rules check it equals the request time.
  static Map<String, dynamic> toNewDoc(WaitlistEntry entry) => {
    'userId': entry.userId,
    'tripId': entry.tripId,
    'phone': entry.phone,
    'origin': entry.origin,
    'destination': entry.destination,
    'operatorName': entry.operatorName,
    'departureTime': Timestamp.fromDate(entry.departure),
    'createdAt': FieldValue.serverTimestamp(),
  };
}
