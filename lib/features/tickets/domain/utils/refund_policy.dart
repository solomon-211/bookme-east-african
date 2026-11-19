import 'package:equatable/equatable.dart';

import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

/// A delay longer than this gives a full refund, like an operator
/// cancellation.
const Duration kLongDelay = Duration(hours: 2);

/// Cancelling at least this long before departure refunds the whole fare.
const Duration kFullFareNotice = Duration(hours: 24);

/// Cancelling at least this long before departure refunds half the fare.
/// Closer to departure the seat can rarely be resold, so nothing is refunded.
const Duration kHalfFareNotice = Duration(hours: 6);

/// Why money comes back, which decides how much.
enum RefundReason {
  /// The operator cancelled the departure.
  operatorCancelled,

  /// The departure is running more than [kLongDelay] late.
  longDelay,

  /// The traveller cancels a trip that is running normally.
  voluntary,
}

/// What the traveller gets back if they cancel now. Shown before they
/// confirm, so there are no surprises.
class RefundQuote extends Equatable {
  const RefundQuote({
    required this.reason,
    required this.paid,
    required this.refund,
  });

  final RefundReason reason;

  /// What was charged for the booking.
  final int paid;

  /// What goes back to the original payment method.
  final int refund;

  /// What BookMe and the operator keep.
  int get kept => paid - refund;

  bool get isFullRefund => refund == paid;

  @override
  List<Object?> get props => [reason, paid, refund];
}

/// The refund for cancelling [ticket] at [now], or `null` when it can no
/// longer be cancelled (not paid, already cancelled, or the bus has left).
///
/// [delay] is how late the operator says the departure is running.
///
/// * Operator cancellation, or a delay over [kLongDelay]: everything back,
///   service fee included.
/// * Traveller cancels [kFullFareNotice] or more before departure: the
///   fare back; the service fee is kept.
/// * [kHalfFareNotice] or more before: half the fare back.
/// * Later than that: nothing back.
RefundQuote? refundQuote(
  Ticket ticket,
  DateTime now, {
  Duration delay = Duration.zero,
}) {
  if (!ticket.canManage(now)) return null;

  final paid = ticket.booking.totalAmount;
  if (ticket.tripStatus == TripStatus.cancelled) {
    return RefundQuote(
      reason: RefundReason.operatorCancelled,
      paid: paid,
      refund: paid,
    );
  }
  if (delay > kLongDelay) {
    return RefundQuote(
      reason: RefundReason.longDelay,
      paid: paid,
      refund: paid,
    );
  }

  // The fee pays for the booking service already given, so a voluntary
  // cancellation never returns it.
  final fare = (paid - ticket.trip.serviceFee).clamp(0, paid);
  final notice = ticket.trip.departure.difference(now);
  final int refund;
  if (notice >= kFullFareNotice) {
    refund = fare;
  } else if (notice >= kHalfFareNotice) {
    refund = fare ~/ 2;
  } else {
    refund = 0;
  }
  return RefundQuote(
    reason: RefundReason.voluntary,
    paid: paid,
    refund: refund,
  );
}
