import 'package:equatable/equatable.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';

/// Operator-side status of a departure, stored as `status` on the trip.
enum TripStatus {
  scheduled,
  delayed,
  cancelled;

  static TripStatus fromName(String? name) => TripStatus.values.firstWhere(
    (s) => s.name == name,
    orElse: () => TripStatus.scheduled,
  );
}

/// A booking joined with the trip it is for.
///
/// The `bookings/{bookingId}` document only stores `tripId`, so the data
/// layer reads `trips/{tripId}` and combines both into one [Ticket]. Every
/// Tickets & Trips screen works with this type and never touches the two
/// documents directly.
class Ticket extends Equatable {
  const Ticket({
    required this.booking,
    required this.trip,
    this.tripStatus = TripStatus.scheduled,
  });

  final Booking booking;
  final TripSummary trip;

  /// Whether the operator is running the departure on time.
  final TripStatus tripStatus;

  String get id => booking.id;

  /// Statuses that belong in My Trips. Holds and expired holds are part of
  /// the booking flow, not real trips, so they are never listed.
  static const Set<BookingStatus> listedStatuses = {
    BookingStatus.paid,
    BookingStatus.cancelled,
  };

  bool get isPaid => booking.status == BookingStatus.paid;

  bool get isCancelled => booking.status == BookingStatus.cancelled;

  /// A paid trip that has not arrived yet. A trip that is on the road right
  /// now still counts as upcoming, because the traveller may need the QR.
  bool isUpcoming(DateTime now) => isPaid && trip.arrival.isAfter(now);

  /// Finished or cancelled trips, shown under the "Past" tab.
  bool isPast(DateTime now) => !isUpcoming(now);

  /// Changes and cancellations are only allowed before the bus leaves.
  bool canManage(DateTime now) => isPaid && trip.departure.isAfter(now);

  /// What the boarding QR code encodes. The reference is what the conductor
  /// reads; the id lets the operator look the booking up directly.
  String get qrPayload => 'BOOKME:${booking.reference}:${booking.id}';

  @override
  List<Object?> get props => [booking, trip, tripStatus];
}
