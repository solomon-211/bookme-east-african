import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';

class OfflineTicketState extends Equatable {
  const OfflineTicketState({this.ticket, this.savedAt});

  /// The ticket as saved on the phone, or `null` if it was never saved.
  final Ticket? ticket;

  /// When the saved copy was last refreshed from the server.
  final DateTime? savedAt;

  bool get isMissing => ticket == null;

  @override
  List<Object?> get props => [ticket, savedAt];
}

/// Drives the offline QR screen. It never touches the network: the ticket
/// comes only from the copy saved on the phone, so the screen opens
/// instantly at a border post with no signal.
class OfflineTicketCubit extends Cubit<OfflineTicketState> {
  OfflineTicketCubit({
    required this._repository,
    required this.bookingId,
    this._fallback,
  }) : super(const OfflineTicketState());

  final TicketsRepository _repository;
  final String bookingId;

  /// The ticket the caller already has on screen (e.g. from My Trips). Used
  /// and saved when the phone has no copy yet.
  final Ticket? _fallback;

  Future<void> load() async {
    final saved = _savedCopy();
    if (saved != null) {
      emit(
        OfflineTicketState(ticket: saved, savedAt: _repository.lastSyncedAt()),
      );
      return;
    }

    final fallback = _fallback;
    if (fallback == null) {
      emit(const OfflineTicketState());
      return;
    }
    emit(OfflineTicketState(ticket: fallback));
    try {
      await _repository.saveForOffline(fallback);
      emit(
        OfflineTicketState(
          ticket: fallback,
          savedAt: _repository.lastSyncedAt(),
        ),
      );
    } on Object {
      // Still shown; it just isn't saved for next time.
    }
  }

  Ticket? _savedCopy() {
    for (final ticket in _repository.cachedTickets()) {
      if (ticket.id == bookingId) return ticket;
    }
    return null;
  }
}
