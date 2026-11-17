import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';

enum MyTripsStatus {
  /// Waiting for the first list, with nothing cached to show.
  loading,

  /// Showing a list (live, or from the cache when [MyTripsState.isOffline]).
  loaded,

  /// Nothing could be loaded and nothing is cached.
  failure,
}

class MyTripsState extends Equatable {
  const MyTripsState({
    this.status = MyTripsStatus.loading,
    this.upcoming = const [],
    this.past = const [],
    this.isOffline = false,
    this.lastSyncedAt,
    this.message,
  });

  /// Splits [tickets] into the two tabs: upcoming trips soonest first, past
  /// and cancelled trips most recent first.
  factory MyTripsState.fromTickets(
    List<Ticket> tickets, {
    required DateTime now,
    bool isOffline = false,
    DateTime? lastSyncedAt,
    String? message,
  }) {
    final upcoming = tickets.where((t) => t.isUpcoming(now)).toList()
      ..sort((a, b) => a.trip.departure.compareTo(b.trip.departure));
    final past = tickets.where((t) => t.isPast(now)).toList()
      ..sort((a, b) => b.trip.departure.compareTo(a.trip.departure));
    return MyTripsState(
      status: MyTripsStatus.loaded,
      upcoming: upcoming,
      past: past,
      isOffline: isOffline,
      lastSyncedAt: lastSyncedAt,
      message: message,
    );
  }

  final MyTripsStatus status;
  final List<Ticket> upcoming;
  final List<Ticket> past;

  /// True when the list comes from the on-device cache because Firestore
  /// could not be reached.
  final bool isOffline;
  final DateTime? lastSyncedAt;
  final String? message;

  /// The trip shown in the big card at the top of the Upcoming tab.
  Ticket? get nextTrip => upcoming.isEmpty ? null : upcoming.first;

  bool get isEmpty => upcoming.isEmpty && past.isEmpty;

  @override
  List<Object?> get props => [
    status,
    upcoming,
    past,
    isOffline,
    lastSyncedAt,
    message,
  ];
}

/// Drives the My Trips screen.
///
/// Shows the cached tickets straight away (so the screen is never blank on
/// a slow connection), then replaces them with the live Firestore list. If
/// the live list fails, the cached tickets stay on screen marked offline.
class MyTripsCubit extends Cubit<MyTripsState> {
  MyTripsCubit({required this._repository, DateTime Function()? clock})
    : _now = clock ?? DateTime.now,
      super(const MyTripsState());

  final TicketsRepository _repository;
  final DateTime Function() _now;
  StreamSubscription<List<Ticket>>? _subscription;

  /// Starts (or restarts, e.g. from a "Try again" button) listening.
  Future<void> load() async {
    await _subscription?.cancel();

    final cached = _repository.cachedTickets();
    emit(
      cached.isEmpty
          ? const MyTripsState()
          : MyTripsState.fromTickets(
              cached,
              now: _now(),
              lastSyncedAt: _repository.lastSyncedAt(),
            ),
    );

    _subscription = _repository.watchMyTickets().listen(
      (tickets) => emit(MyTripsState.fromTickets(tickets, now: _now())),
      onError: _onError,
    );
  }

  void _onError(Object error) {
    final message = error is BookingFailure
        ? error.message
        : 'We couldn\'t load your trips. Please try again.';
    final cached = _repository.cachedTickets();
    if (cached.isEmpty) {
      emit(MyTripsState(status: MyTripsStatus.failure, message: message));
      return;
    }
    emit(
      MyTripsState.fromTickets(
        cached,
        now: _now(),
        isOffline: true,
        lastSyncedAt: _repository.lastSyncedAt(),
        message: message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
