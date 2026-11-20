import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/account_repository.dart';
import '../domain/saved_passenger.dart';
import '../domain/user_profile.dart';
import 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._repository) : super(const AccountState());

  final AccountRepository _repository;
  StreamSubscription<UserProfile?>? _profileSub;
  StreamSubscription<List<SavedPassenger>>? _passengerSub;

  void start() {
    _profileSub?.cancel();
    _passengerSub?.cancel();

    _profileSub = _repository.watchProfile().listen(
      (profile) => emit(
        profile == null
            ? state.copyWith(status: AccountStatus.signedOut)
            : state.copyWith(status: AccountStatus.ready, profile: profile),
      ),
      onError: (_) => emit(state.copyWith(status: AccountStatus.failure)),
    );

    _passengerSub = _repository.watchPassengers().listen(
      (passengers) => emit(state.copyWith(passengers: passengers)),
      onError: (_) =>
          emit(state.withMessage('We couldn\'t load your saved passengers.')),
    );
  }

  // Each method returns true when the save worked, so a form can close.

  Future<bool> updateProfile(UserProfile profile) =>
      _save(() => _repository.updateProfile(profile), 'Profile updated');

  Future<bool> addPassenger(SavedPassenger passenger) =>
      _save(() => _repository.addPassenger(passenger), 'Passenger saved');

  Future<bool> updatePassenger(SavedPassenger passenger) =>
      _save(() => _repository.updatePassenger(passenger), 'Passenger updated');

  Future<bool> deletePassenger(SavedPassenger passenger) => _save(
    () => _repository.deletePassenger(passenger.id),
    '${passenger.fullName} removed',
  );

  Future<bool> _save(Future<void> Function() action, String done) async {
    emit(state.copyWith(saving: true));
    try {
      await action();
      emit(state.withMessage(done));
      return true;
    } on AccountFailure catch (e) {
      emit(state.withMessage(e.message));
    } catch (_) {
      emit(state.withMessage('Something went wrong. Please try again.'));
    }
    return false;
  }

  @override
  Future<void> close() {
    _profileSub?.cancel();
    _passengerSub?.cancel();
    return super.close();
  }
}
