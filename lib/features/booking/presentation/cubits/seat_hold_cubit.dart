import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/booking/domain/repositories/booking_repository.dart';

enum SeatHoldStatus {
  /// Asking Firestore for a seat.
  holding,

  /// Seat reserved; the countdown is running.
  active,

  /// The countdown reached zero and the seat was released.
  expired,

  /// The booking was paid, so the countdown no longer matters.
  completed,

  /// No seat could be held (bus full, offline...).
  failure,
}

class SeatHoldState extends Equatable {
  const SeatHoldState({
    this.status = SeatHoldStatus.holding,
    this.booking,
    this.remaining = kSeatHoldDuration,
    this.message,
  });

  final SeatHoldStatus status;
  final Booking? booking;
  final Duration remaining;
  final String? message;

  /// 1.0 when the hold starts, 0.0 when it runs out. Drives the thin
  /// progress bar under the timer banner.
  double get progress {
    final b = booking;
    if (b == null) return 1;
    final total = b.holdExpiresAt.difference(b.createdAt).inMilliseconds;
    if (total <= 0) return 0;
    return (remaining.inMilliseconds / total).clamp(0, 1).toDouble();
  }

  SeatHoldState copyWith({
    SeatHoldStatus? status,
    Booking? booking,
    Duration? remaining,
    String? message,
  }) {
    return SeatHoldState(
      status: status ?? this.status,
      booking: booking ?? this.booking,
      remaining: remaining ?? this.remaining,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, booking, remaining, message];
}

/// Owns the 10-minute seat hold for the whole booking flow.
///
/// One instance is shared by all five booking screens, so the timer banner
/// on every screen shows the same countdown and they all react when it
/// expires.
class SeatHoldCubit extends Cubit<SeatHoldState> {
  SeatHoldCubit({
    required this._repository,
    Stream<DateTime> Function()? ticker,
    DateTime Function()? clock,
  }) : _ticker = ticker ?? _everySecond,
       _now = clock ?? DateTime.now,
       super(const SeatHoldState());

  final BookingRepository _repository;
  final Stream<DateTime> Function() _ticker;
  final DateTime Function() _now;

  StreamSubscription<DateTime>? _tickSub;
  StreamSubscription<Booking>? _bookingSub;

  static Stream<DateTime> _everySecond() => Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );

  Future<void> start(TripSummary trip) async {
    emit(const SeatHoldState());
    try {
      final booking = await _repository.holdSeat(trip);
      if (isClosed) return;
      _onBooking(booking);
      // Picks up changes made elsewhere: passenger saved, hold extended for
      // a payment request, or the booking becoming paid.
      _bookingSub = _repository
          .watchBooking(booking.id)
          .listen(_onBooking, onError: (Object _) {});
      _tickSub = _ticker().listen(_onTick);
    } on BookingFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: SeatHoldStatus.failure,
            message: failure.message,
          ),
        );
      }
    }
  }

  void _onBooking(Booking booking) {
    if (isClosed) return;
    switch (booking.status) {
      case BookingStatus.held:
        if (state.status == SeatHoldStatus.expired) return;
        emit(
          state.copyWith(
            status: SeatHoldStatus.active,
            booking: booking,
            remaining: booking.remainingHold(_now()),
          ),
        );
      case BookingStatus.paid:
        _tickSub?.cancel();
        emit(
          state.copyWith(
            status: SeatHoldStatus.completed,
            booking: booking,
            remaining: Duration.zero,
          ),
        );
      case BookingStatus.expired:
      case BookingStatus.cancelled:
        _tickSub?.cancel();
        emit(
          state.copyWith(
            status: SeatHoldStatus.expired,
            booking: booking,
            remaining: Duration.zero,
          ),
        );
    }
  }

  void _onTick(DateTime now) {
    final booking = state.booking;
    if (booking == null || state.status != SeatHoldStatus.active) return;

    final remaining = booking.remainingHold(now);
    if (remaining > Duration.zero) {
      emit(state.copyWith(remaining: remaining));
      return;
    }
    _tickSub?.cancel();
    emit(
      state.copyWith(status: SeatHoldStatus.expired, remaining: Duration.zero),
    );
    unawaited(_repository.releaseHold(booking));
  }

  @override
  Future<void> close() async {
    // Leaving the flow without paying gives the seat back straight away.
    // The data layer checks the booking is still unpaid before releasing.
    final booking = state.booking;
    if (state.status == SeatHoldStatus.active && booking != null) {
      unawaited(_repository.releaseHold(booking));
    }
    await _tickSub?.cancel();
    await _bookingSub?.cancel();
    return super.close();
  }
}
