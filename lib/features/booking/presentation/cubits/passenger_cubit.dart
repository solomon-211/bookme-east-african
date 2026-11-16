import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/passenger.dart';
import 'package:bookme_summative_project/features/booking/domain/repositories/booking_repository.dart';

enum PassengerFormStatus { editing, saving, saved }

class PassengerState extends Equatable {
  const PassengerState({
    this.status = PassengerFormStatus.editing,
    this.someoneElsePaying = false,
    this.passenger,
    this.message,
  });

  final PassengerFormStatus status;

  /// When true the flow goes to "Request payment" instead of "Pay".
  final bool someoneElsePaying;
  final Passenger? passenger;

  /// Error to show in a snack bar, if the last save failed.
  final String? message;

  PassengerState copyWith({
    PassengerFormStatus? status,
    bool? someoneElsePaying,
    Passenger? passenger,
    String? message,
    bool clearMessage = false,
  }) {
    return PassengerState(
      status: status ?? this.status,
      someoneElsePaying: someoneElsePaying ?? this.someoneElsePaying,
      passenger: passenger ?? this.passenger,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, someoneElsePaying, passenger, message];
}

/// Saves "Who's travelling?" and remembers who is paying.
class PassengerCubit extends Cubit<PassengerState> {
  PassengerCubit({required this._repository}) : super(const PassengerState());

  final BookingRepository _repository;

  void setSomeoneElsePaying(bool value) =>
      emit(state.copyWith(someoneElsePaying: value, clearMessage: true));

  Future<void> submit({
    required String bookingId,
    required Passenger passenger,
  }) async {
    if (state.status == PassengerFormStatus.saving) return;
    emit(
      state.copyWith(status: PassengerFormStatus.saving, clearMessage: true),
    );
    try {
      await _repository.savePassenger(
        bookingId: bookingId,
        passenger: passenger,
      );
      emit(
        state.copyWith(status: PassengerFormStatus.saved, passenger: passenger),
      );
    } on BookingFailure catch (failure) {
      emit(
        state.copyWith(
          status: PassengerFormStatus.editing,
          message: failure.message,
        ),
      );
    }
  }
}
