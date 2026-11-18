import 'package:bookme_summative_project/features/account/data/in_memory_account_repository.dart';
import 'package:bookme_summative_project/features/account/domain/saved_passenger.dart';
import 'package:bookme_summative_project/features/account/domain/user_profile.dart';
import 'package:bookme_summative_project/features/account/presentation/account_cubit.dart';
import 'package:bookme_summative_project/features/account/presentation/account_state.dart';
import 'package:flutter_test/flutter_test.dart';

const amani = SavedPassenger(
  id: '',
  fullName: 'Amani Uwase',
  phone: '+250788111222',
  idNumber: 'PC1234567',
  nationality: 'Rwanda',
);

void main() {
  late InMemoryAccountRepository repo;
  late AccountCubit cubit;

  setUp(() {
    repo = InMemoryAccountRepository.demo();
    cubit = AccountCubit(repo)..start();
  });

  tearDown(() => cubit.close());

  // Lets the repository streams deliver their latest value.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('start loads the profile and saved passengers', () async {
    await settle();

    expect(cubit.state.status, AccountStatus.ready);
    expect(cubit.state.profile!.fullName, 'Moses Mugisha');
    expect(cubit.state.passengers, hasLength(1));
    expect(cubit.state.passengersSummary, 'Moses Mugisha · 1 passenger');
  });

  test('updateProfile saves and the screen sees the new name', () async {
    await settle();
    final updated = cubit.state.profile!.copyWith(fullName: 'Moses K. Mugisha');

    final ok = await cubit.updateProfile(updated);
    await settle();

    expect(ok, isTrue);
    expect(cubit.state.profile!.fullName, 'Moses K. Mugisha');
    expect(cubit.state.message, 'Profile updated');
  });

  group('saved passengers CRUD', () {
    test('create: addPassenger gives it an id', () async {
      await cubit.addPassenger(amani);
      await settle();

      expect(cubit.state.passengers, hasLength(2));
      final saved = cubit.state.passengers.last;
      expect(saved.fullName, 'Amani Uwase');
      expect(saved.id, isNotEmpty);
      expect(cubit.state.passengersSummary, 'Moses Mugisha · 2 passengers');
    });

    test('update: editPassenger changes only that passenger', () async {
      await cubit.addPassenger(amani);
      await settle();
      final saved = cubit.state.passengers.last;

      await cubit.updatePassenger(saved.copyWith(nationality: 'Uganda'));
      await settle();

      expect(cubit.state.passengers.last.nationality, 'Uganda');
      expect(cubit.state.passengers.first.nationality, 'Rwanda');
    });

    test('delete: deletePassenger removes it', () async {
      await settle();
      final moses = cubit.state.passengers.single;

      await cubit.deletePassenger(moses);
      await settle();

      expect(cubit.state.passengers, isEmpty);
      expect(cubit.state.message, 'Moses Mugisha removed');
    });
  });

  test('a failed save returns false and shows a message', () async {
    await settle();
    repo.failWrites = true;

    final ok = await cubit.addPassenger(amani);

    expect(ok, isFalse);
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.message, 'Something went wrong.');
  });

  test('signed out when there is no profile', () async {
    final empty = AccountCubit(InMemoryAccountRepository())..start();
    await settle();

    expect(empty.state.status, AccountStatus.signedOut);
    await empty.close();
  });

  group('UserProfile', () {
    test('initials use first and last name', () {
      const p = UserProfile(uid: 'u', fullName: 'Moses Mugisha', phone: '');
      expect(p.initials, 'MM');
      expect(p.copyWith(fullName: 'Amani').initials, 'A');
      expect(p.copyWith(fullName: '  ').initials, '?');
    });

    test('ID summary shows only the last four digits', () {
      const id = IdDocument(
        type: 'EAC ID',
        country: 'Rwanda',
        number: '1199880044120036',
      );
      expect(id.summary, 'EAC ID · Rwanda · Ending 0036');
    });
  });
}
