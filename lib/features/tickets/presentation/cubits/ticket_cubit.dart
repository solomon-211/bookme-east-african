import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';

enum TicketStatus {
  /// Waiting for the ticket, with no saved copy to show.
  loading,

  /// Showing the ticket (live, or the saved copy when offline).
  loaded,

  /// The ticket could not be loaded and no copy is saved on the phone.
  failure,
}

class TicketState extends Equatable {
  const TicketState({
    this.status = TicketStatus.loading,
    this.ticket,
    this.isOffline = false,
    this.savedAt,
    this.message,
  });

  final TicketStatus status;
  final Ticket? ticket;

  /// True when [ticket] is the copy saved on the phone because Firestore
  /// could not be reached.
  final bool isOffline;

  /// Set each time "Save to Phone" succeeds, so the screen can confirm it.
  final DateTime? savedAt;
  final String? message;

  TicketState copyWith({
    TicketStatus? status,
    Ticket? ticket,
    bool? isOffline,
    DateTime? savedAt,
    String? message,
  }) => TicketState(
    status: status ?? this.status,
    ticket: ticket ?? this.ticket,
    isOffline: isOffline ?? this.isOffline,
    savedAt: savedAt ?? this.savedAt,
    message: message ?? this.message,
  );

  @override
  List<Object?> get props => [status, ticket, isOffline, savedAt, message];
}

/// Drives the Digital Ticket screen for one booking.
///
/// Shows the copy saved on the phone straight away, then follows the live
/// booking. Every live update is saved back to the phone, so the QR code
/// keeps working at a border post with no signal.
class TicketCubit extends Cubit<TicketState> {
  TicketCubit({
    required this._repository,
    required this.bookingId,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(const TicketState());

  final TicketsRepository _repository;
  final String bookingId;
  final DateTime Function() _now;
  StreamSubscription<Ticket>? _subscription;

  Future<void> load() async {
    await _subscription?.cancel();

    final saved = _savedCopy();
    emit(
      saved == null
          ? const TicketState()
          : TicketState(status: TicketStatus.loaded, ticket: saved),
    );

    _subscription = _repository
        .watchTicket(bookingId)
        .listen(_onTicket, onError: _onError);
  }

  /// "Save to Phone / Wallet".
  Future<void> saveToPhone() async {
    final ticket = state.ticket;
    if (ticket == null) return;
    try {
      await _repository.saveForOffline(ticket);
      emit(state.copyWith(savedAt: _now()));
    } on Object {
      emit(
        state.copyWith(
          message:
              'We couldn\'t save the ticket on this phone. '
              'Check your storage and try again.',
        ),
      );
    }
  }

  Future<void> _onTicket(Ticket ticket) async {
    emit(TicketState(status: TicketStatus.loaded, ticket: ticket));
    try {
      await _repository.saveForOffline(ticket);
    } on Object {
      // The live ticket is on screen; an older saved copy is still fine.
    }
  }

  void _onError(Object error) {
    final message = error is BookingFailure
        ? error.message
        : 'We couldn\'t load this ticket. Please try again.';
    final saved = state.ticket ?? _savedCopy();
    emit(
      saved == null
          ? TicketState(status: TicketStatus.failure, message: message)
          : TicketState(
              status: TicketStatus.loaded,
              ticket: saved,
              isOffline: true,
              message: message,
            ),
    );
  }

  Ticket? _savedCopy() {
    for (final ticket in _repository.cachedTickets()) {
      if (ticket.id == bookingId) return ticket;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
