import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/date_change.dart';

enum ChangeDateStatus {
  loading,

  /// The other departures could not be loaded; [ChangeDateState.message]
  /// says why.
  failed,
  ready,

  /// The move is being saved; the list and button are disabled.
  changing,

  /// The booking was moved; the page closes with [ChangeDateState.changed].
  changed,
}

class ChangeDateState extends Equatable {
  const ChangeDateState({
    this.status = ChangeDateStatus.loading,
    this.trips = const [],
    this.selected,
    this.changed,
    this.message,
  });

  final ChangeDateStatus status;

  /// Other departures on the same route, soonest first.
  final List<TripSummary> trips;
  final TripSummary? selected;

  /// The moved booking, once [status] is [ChangeDateStatus.changed].
  final Ticket? changed;

  /// Error to show once.
  final String? message;

  bool get isChanging => status == ChangeDateStatus.changing;

  @override
  List<Object?> get props => [status, trips, selected, changed, message];
}

/// Drives "Change date / time": lists the other departures with their fare
/// difference and moves the booking to the one picked.
class ChangeDateCubit extends Cubit<ChangeDateState> {
  ChangeDateCubit({
    required this._repository,
    required this.ticket,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(const ChangeDateState());

  final TicketsRepository _repository;
  final DateTime Function() _now;

  /// The booking being moved.
  final Ticket ticket;

  /// The price difference of moving to [trip], or `null` if it's no longer
  /// allowed (for example, it has just left).
  DateChangeQuote? quoteFor(TripSummary trip) =>
      dateChangeQuote(ticket, trip, _now());

  /// Whether [trip] can be picked. Dearer departures can't until paying a
  /// difference is supported.
  bool canPick(TripSummary trip) => quoteFor(trip)?.needsTopUp == false;

  Future<void> load() async {
    emit(const ChangeDateState());
    try {
      final trips = await _repository.alternativeTrips(ticket);
      if (isClosed) return;
      emit(ChangeDateState(status: ChangeDateStatus.ready, trips: trips));
    } on BookingFailure catch (e) {
      if (isClosed) return;
      emit(
        ChangeDateState(status: ChangeDateStatus.failed, message: e.message),
      );
    }
  }

  void select(TripSummary trip) {
    if (state.status != ChangeDateStatus.ready || !canPick(trip)) return;
    emit(
      ChangeDateState(
        status: ChangeDateStatus.ready,
        trips: state.trips,
        selected: trip,
      ),
    );
  }

  Future<void> confirm() async {
    final selected = state.selected;
    if (selected == null || state.status != ChangeDateStatus.ready) return;
    emit(
      ChangeDateState(
        status: ChangeDateStatus.changing,
        trips: state.trips,
        selected: selected,
      ),
    );
    try {
      final changed = await _repository.changeTrip(ticket, selected);
      emit(
        ChangeDateState(
          status: ChangeDateStatus.changed,
          trips: state.trips,
          selected: selected,
          changed: changed,
        ),
      );
    } on BookingFailure catch (e) {
      // Usually the seats ran out; keep the list so another can be picked.
      emit(
        ChangeDateState(
          status: ChangeDateStatus.ready,
          trips: state.trips,
          message: e.message,
        ),
      );
    }
  }
}
