import 'dart:async';

import '../domain/account_repository.dart';
import '../domain/saved_passenger.dart';
import '../domain/user_profile.dart';

// Account data kept in memory, for the offline demo and the tests.
// Everything is lost when the app restarts.
class InMemoryAccountRepository implements AccountRepository {
  InMemoryAccountRepository({
    UserProfile? profile,
    List<SavedPassenger>? passengers,
  }) : _profile = profile, // ignore: prefer_initializing_formals
       _passengers = [...?passengers];

  UserProfile? _profile;
  final List<SavedPassenger> _passengers;
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  // Set to true in tests to check how the UI handles a failed save.
  bool failWrites = false;

  factory InMemoryAccountRepository.demo() => InMemoryAccountRepository(
    profile: const UserProfile(
      uid: 'demo-user',
      fullName: 'Moses Mugisha',
      phone: '+250781234412',
      email: 'moses.mugisha@example.com',
      phoneVerified: true,
      idDocument: IdDocument(
        type: 'EAC ID',
        country: 'Rwanda',
        number: '1199880044120036',
      ),
      mobileMoney: MobileMoneyAccount(
        provider: 'MTN MoMo',
        phone: '+250781234412',
      ),
    ),
    passengers: const [
      SavedPassenger(
        id: 'p-self',
        fullName: 'Moses Mugisha',
        phone: '+250781234412',
        idNumber: '1199880044120036',
        nationality: 'Rwanda',
      ),
    ],
  );

  Stream<T> _watch<T>(T Function() current) async* {
    yield current();
    await for (final _ in _changes.stream) {
      yield current();
    }
  }

  void _check() {
    if (failWrites) throw const AccountFailure('Something went wrong.');
  }

  @override
  Stream<UserProfile?> watchProfile() => _watch(() => _profile);

  @override
  Future<void> updateProfile(UserProfile profile) async {
    _check();
    _profile = profile;
    _changes.add(null);
  }

  @override
  Stream<List<SavedPassenger>> watchPassengers() =>
      _watch(() => List.unmodifiable(_passengers));

  @override
  Future<SavedPassenger> addPassenger(SavedPassenger passenger) async {
    _check();
    final saved = passenger.copyWith(id: 'p-${_nextId++}');
    _passengers.add(saved);
    _changes.add(null);
    return saved;
  }

  @override
  Future<void> updatePassenger(SavedPassenger passenger) async {
    _check();
    final i = _passengers.indexWhere((p) => p.id == passenger.id);
    if (i == -1) throw const AccountFailure('That passenger was removed.');
    _passengers[i] = passenger;
    _changes.add(null);
  }

  @override
  Future<void> deletePassenger(String passengerId) async {
    _check();
    _passengers.removeWhere((p) => p.id == passengerId);
    _changes.add(null);
  }
}
