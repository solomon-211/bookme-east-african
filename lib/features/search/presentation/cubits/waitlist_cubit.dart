import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/booking/domain/validators/passenger_validators.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/entities/waitlist_entry.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/search_repository.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/waitlist_repository.dart';

class WaitlistState extends Equatable {
  const WaitlistState({
    this.entries = const [],
    this.busyTripId,
    this.errorMessage,
  });

  final List<WaitlistEntry> entries;

  /// Trip whose join/leave is in progress, to show a spinner on its card.
  final String? busyTripId;
  final String? errorMessage;

  WaitlistEntry? entryFor(String tripId) {
    for (final entry in entries) {
      if (entry.tripId == tripId) return entry;
    }
    return null;
  }

  bool isOnWaitlist(String tripId) => entryFor(tripId) != null;

  WaitlistState copyWith({
    List<WaitlistEntry>? entries,
    String? busyTripId,
    bool clearBusy = false,
    String? errorMessage,
    bool clearError = false,
  }) => WaitlistState(
    entries: entries ?? this.entries,
    busyTripId: clearBusy ? null : (busyTripId ?? this.busyTripId),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [entries, busyTripId, errorMessage];
}

/// The traveller's waitlist: join a fully booked bus, or leave it.
class WaitlistCubit extends Cubit<WaitlistState> {
  WaitlistCubit({required this._repository}) : super(const WaitlistState());

  final WaitlistRepository _repository;
  StreamSubscription<List<WaitlistEntry>>? _sub;

  /// Starts listening to the traveller's entries.
  void start() {
    _sub?.cancel();
    _sub = _repository.watchMine().listen(
      (entries) => emit(state.copyWith(entries: entries)),
      onError: (Object _) => emit(
        state.copyWith(errorMessage: 'We couldn\'t load your waitlist.'),
      ),
    );
  }

  /// `null` if [phone] can receive the SMS, otherwise what to fix.
  static String? validatePhone(String? phone) => PassengerValidators.phone(phone);

  /// Joins [trip]'s waitlist. Returns the entry, or `null` on failure
  /// (the reason is in [WaitlistState.errorMessage]).
  Future<WaitlistEntry?> join(BusTrip trip, String phone) async {
    final existing = state.entryFor(trip.id);
    if (existing != null) return existing;
    if (validatePhone(phone) case final problem?) {
      emit(state.copyWith(errorMessage: problem));
      return null;
    }
    emit(state.copyWith(busyTripId: trip.id, clearError: true));
    try {
      final entry = await _repository.join(
        trip: trip,
        phone: PassengerValidators.normalizePhone(phone),
      );
      // Shown straight away; the live stream confirms it shortly after.
      final entries = [
        entry,
        ...state.entries.where((e) => e.id != entry.id),
      ];
      emit(state.copyWith(entries: entries, clearBusy: true));
      return entry;
    } on SearchFailure catch (e) {
      emit(state.copyWith(errorMessage: e.message, clearBusy: true));
      return null;
    }
  }

  /// Leaves the waitlist for [tripId]. Returns whether it worked.
  Future<bool> leave(String tripId) async {
    final entry = state.entryFor(tripId);
    if (entry == null) return true;
    emit(state.copyWith(busyTripId: tripId, clearError: true));
    try {
      await _repository.leave(entry.id);
      emit(
        state.copyWith(
          entries: state.entries.where((e) => e.id != entry.id).toList(),
          clearBusy: true,
        ),
      );
      return true;
    } on SearchFailure catch (e) {
      emit(state.copyWith(errorMessage: e.message, clearBusy: true));
      return false;
    }
  }

  void clearError() => emit(state.copyWith(clearError: true));

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
