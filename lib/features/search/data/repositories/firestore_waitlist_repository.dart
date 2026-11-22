import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bookme_summative_project/features/search/data/models/waitlist_entry_model.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/entities/waitlist_entry.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/search_repository.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/waitlist_repository.dart';

/// `waitlist/{userId}_{tripId}` in Firestore.
///
/// Security rules let a user create, read and delete only their own
/// entries, and never update them.
class FirestoreWaitlistRepository implements WaitlistRepository {
  FirestoreWaitlistRepository({
    required FirebaseFirestore firestore,
    required String? Function() currentUserId,
  }) : _db = firestore,
       _uid = currentUserId;

  final FirebaseFirestore _db;
  final String? Function() _uid;

  CollectionReference<Map<String, dynamic>> get _waitlist =>
      _db.collection('waitlist');

  /// Composite index: userId ASC, createdAt DESC.
  @override
  Stream<List<WaitlistEntry>> watchMine() {
    final uid = _uid();
    if (uid == null) return Stream.value(const []);
    return _waitlist
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              ?WaitlistEntryModel.fromMap(doc.id, doc.data()),
          ],
        );
  }

  @override
  Future<WaitlistEntry> join({
    required BusTrip trip,
    required String phone,
  }) async {
    final uid = _uid();
    if (uid == null) {
      throw const SearchFailure('Please sign in again to join the waitlist.');
    }
    final entry = WaitlistEntry(
      id: WaitlistEntry.idFor(uid, trip.id),
      userId: uid,
      tripId: trip.id,
      phone: phone,
      origin: trip.origin,
      destination: trip.destination,
      operatorName: trip.operatorName,
      departure: trip.departure,
    );
    try {
      await _waitlist.doc(entry.id).set(WaitlistEntryModel.toNewDoc(entry));
      return entry;
    } on FirebaseException catch (e) {
      throw SearchFailure(
        e.code == 'unavailable'
            ? 'You seem to be offline. Try again when you\'re connected.'
            : 'We couldn\'t add you to the waitlist. Please try again.',
      );
    }
  }

  @override
  Future<void> leave(String entryId) async {
    try {
      await _waitlist.doc(entryId).delete();
    } on FirebaseException {
      throw const SearchFailure(
        'We couldn\'t remove you from the waitlist. Please try again.',
      );
    }
  }
}
