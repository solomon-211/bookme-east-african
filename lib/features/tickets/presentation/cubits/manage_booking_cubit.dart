import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';

enum ManageBookingStatus {
  idle,

  /// A cancel or remove is in progress; the buttons are disabled.
  working,

  /// The trip was removed from history; the page closes.
  removed,
}

class ManageBookingState extends Equatable {
  const ManageBookingState({
    required this.ticket,
    this.quote,
    this.status = ManageBookingStatus.idle,
    this.refunded,
    this.message,
  });

  final Ticket ticket;

  /// What cancelling now would refund, or `null` when it can't be cancelled.
  final RefundQuote? quote;
  final ManageBookingStatus status;

  /// The refund recorded by a cancellation made on this page.
  final RefundQuote? refunded;

  /// Confirmation or error to show once.
  final String? message;

  bool get isWorking => status == ManageBookingStatus.working;

  @override
  List<Object?> get props => [ticket, quote, status, refunded, message];
}

/// Drives Manage Booking: cancelling with a refund, and removing a
/// cancelled or finished trip from history.
class ManageBookingCubit extends Cubit<ManageBookingState> {
  ManageBookingCubit({
    required this._repository,
    required Ticket ticket,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(
         ManageBookingState(
           ticket: ticket,
           quote: refundQuote(ticket, (clock ?? DateTime.now)()),
         ),
       );

  final TicketsRepository _repository;
  final DateTime Function() _now;

  /// Whether "Remove from history" is offered.
  bool get canRemove => state.ticket.isPast(_now());

  Future<void> cancel() async {
    if (state.isWorking || state.quote == null) return;
    emit(_copy(status: ManageBookingStatus.working));
    try {
      final refund = await _repository.cancelBooking(state.ticket);
      final cancelled = Ticket(
        booking: state.ticket.booking.copyWith(status: BookingStatus.cancelled),
        trip: state.ticket.trip,
        tripStatus: state.ticket.tripStatus,
      );
      emit(
        ManageBookingState(
          ticket: cancelled,
          refunded: refund,
          message: 'Booking cancelled.',
        ),
      );
    } on BookingFailure catch (e) {
      emit(_copy(status: ManageBookingStatus.idle, message: e.message));
    }
  }

  /// The booking was moved to another departure; the refund for
  /// cancelling is worked out again for the new trip.
  void ticketChanged(Ticket ticket) {
    if (isClosed) return;
    emit(
      ManageBookingState(ticket: ticket, quote: refundQuote(ticket, _now())),
    );
  }

  Future<void> remove() async {
    if (state.isWorking || !canRemove) return;
    emit(_copy(status: ManageBookingStatus.working));
    try {
      await _repository.removeFromHistory(state.ticket);
      emit(_copy(status: ManageBookingStatus.removed));
    } on BookingFailure catch (e) {
      emit(_copy(status: ManageBookingStatus.idle, message: e.message));
    }
  }

  ManageBookingState _copy({
    required ManageBookingStatus status,
    String? message,
  }) => ManageBookingState(
    ticket: state.ticket,
    quote: state.quote,
    status: status,
    refunded: state.refunded,
    message: message,
  );
}
