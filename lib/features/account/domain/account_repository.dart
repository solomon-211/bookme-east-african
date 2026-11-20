import 'saved_passenger.dart';
import 'user_profile.dart';

class AccountFailure implements Exception {
  const AccountFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AccountRepository {
  // Null when nobody is signed in.
  Stream<UserProfile?> watchProfile();

  Future<void> updateProfile(UserProfile profile);

  Stream<List<SavedPassenger>> watchPassengers();

  // Returns the passenger with its new id.
  Future<SavedPassenger> addPassenger(SavedPassenger passenger);

  Future<void> updatePassenger(SavedPassenger passenger);

  Future<void> deletePassenger(String passengerId);
}
