import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/journey_checklist_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';

class ReadyForJourneyState extends Equatable {
  const ReadyForJourneyState({
    this.checked = const {},
    this.savedOffline = false,
    this.message,
  });

  /// Ids of the travel documents the traveller has ticked.
  final Set<String> checked;

  /// Whether the ticket (and so its QR) is saved on this phone.
  final bool savedOffline;
  final String? message;

  @override
  List<Object?> get props => [checked, savedOffline, message];
}

/// Drives Ready for Journey: the document ticks and whether the QR is
/// available offline. Everything here is on the phone, so it works with no
/// connection.
class ReadyForJourneyCubit extends Cubit<ReadyForJourneyState> {
  ReadyForJourneyCubit({
    required this._tickets,
    required this._checklist,
    required this.ticket,
  }) : super(const ReadyForJourneyState());

  final TicketsRepository _tickets;
  final JourneyChecklistRepository _checklist;
  final Ticket ticket;

  void load() {
    emit(
      ReadyForJourneyState(
        checked: _checklist.checkedItems(ticket.id),
        savedOffline: _tickets.cachedTickets().any((t) => t.id == ticket.id),
      ),
    );
  }

  Future<void> toggle(String itemId) async {
    final wasChecked = state.checked.contains(itemId);
    final next = {...state.checked};
    if (wasChecked) {
      next.remove(itemId);
    } else {
      next.add(itemId);
    }
    emit(ReadyForJourneyState(checked: next, savedOffline: state.savedOffline));
    try {
      await _checklist.setChecked(ticket.id, itemId, checked: !wasChecked);
    } on Object {
      emit(
        ReadyForJourneyState(
          checked: _checklist.checkedItems(ticket.id),
          savedOffline: state.savedOffline,
          message: 'We couldn\'t save that tick. Please try again.',
        ),
      );
    }
  }
}
