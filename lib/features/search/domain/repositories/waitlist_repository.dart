import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/entities/waitlist_entry.dart';

/// The signed-in traveller's waitlist entries (create, read, delete).
abstract class WaitlistRepository {
  /// Live list of the traveller's entries, newest first.
  Stream<List<WaitlistEntry>> watchMine();

  /// Adds the traveller to [trip]'s waitlist. [phone] is E.164.
  Future<WaitlistEntry> join({required BusTrip trip, required String phone});

  /// Removes one of the traveller's entries.
  Future<void> leave(String entryId);
}
