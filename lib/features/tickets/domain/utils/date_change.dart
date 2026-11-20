import 'package:equatable/equatable.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

/// The price difference of moving a booking to [newTrip], shown before the
/// traveller confirms.
class DateChangeQuote extends Equatable {
  const DateChangeQuote({required this.paid, required this.newTrip});

  /// What was charged for the booking so far.
  final int paid;
  final TripSummary newTrip;

  int get newTotal => newTrip.total;

  /// Positive when the new departure costs more, negative when it costs less.
  int get difference => newTotal - paid;

  /// Paying a difference in the app is not available yet, so these changes
  /// are refused (see `TicketsRepository.changeTrip`).
  bool get needsTopUp => difference > 0;

  /// Returned to the original payment method when the new trip is cheaper.
  int get refund => difference < 0 ? -difference : 0;

  @override
  List<Object?> get props => [paid, newTrip];
}

/// Whether [newTrip] is a departure [ticket] can move to at [now]: the
/// booking can still be managed, the new trip is a different departure on
/// the same route, and it has not left yet.
bool canChangeTo(Ticket ticket, TripSummary newTrip, DateTime now) =>
    ticket.canManage(now) &&
    newTrip.tripId != ticket.trip.tripId &&
    newTrip.fromCode == ticket.trip.fromCode &&
    newTrip.toCode == ticket.trip.toCode &&
    newTrip.departure.isAfter(now);

/// The quote for moving [ticket] to [newTrip], or `null` when
/// [canChangeTo] says the move is not allowed.
DateChangeQuote? dateChangeQuote(
  Ticket ticket,
  TripSummary newTrip,
  DateTime now,
) {
  if (!canChangeTo(ticket, newTrip, now)) return null;
  return DateChangeQuote(paid: ticket.booking.totalAmount, newTrip: newTrip);
}
