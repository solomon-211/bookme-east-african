import 'package:flutter_test/flutter_test.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';

import '../../../helpers/test_ticket.dart';

void main() {
  // testTicket: 18,500 RWF paid (18,000 fare + 500 service fee), departing
  // 4 Dec 2026 at 21:00.
  final departure = DateTime(2026, 12, 4, 21);
  DateTime hoursBefore(int hours) => departure.subtract(Duration(hours: hours));

  Ticket withTripStatus(TripStatus status) {
    final base = testTicket();
    return Ticket(booking: base.booking, trip: base.trip, tripStatus: status);
  }

  group('operator problems refund everything', () {
    test('an operator cancellation refunds the full total', () {
      final quote = refundQuote(
        withTripStatus(TripStatus.cancelled),
        hoursBefore(1),
      );

      expect(quote!.reason, RefundReason.operatorCancelled);
      expect(quote.refund, 18500);
      expect(quote.isFullRefund, isTrue);
    });

    test('a delay over 2 hours refunds the full total', () {
      final quote = refundQuote(
        withTripStatus(TripStatus.delayed),
        hoursBefore(1),
        delay: const Duration(hours: 2, minutes: 1),
      );

      expect(quote!.reason, RefundReason.longDelay);
      expect(quote.refund, 18500);
    });

    test('a delay of exactly 2 hours follows the fare policy', () {
      final quote = refundQuote(
        withTripStatus(TripStatus.delayed),
        hoursBefore(1),
        delay: const Duration(hours: 2),
      );

      expect(quote!.reason, RefundReason.voluntary);
      expect(quote.refund, 0);
    });
  });

  group('cancelling yourself', () {
    test('24 hours or more before departure refunds the fare', () {
      final quote = refundQuote(testTicket(), hoursBefore(24))!;

      expect(quote.reason, RefundReason.voluntary);
      expect(quote.refund, 18000);
      expect(quote.kept, 500); // The service fee.
    });

    test('6 to 24 hours before departure refunds half the fare', () {
      expect(refundQuote(testTicket(), hoursBefore(23))!.refund, 9000);
      expect(refundQuote(testTicket(), hoursBefore(6))!.refund, 9000);
    });

    test('under 6 hours before departure refunds nothing', () {
      final quote = refundQuote(testTicket(), hoursBefore(5))!;

      expect(quote.refund, 0);
      expect(quote.kept, 18500);
    });
  });

  group('no refund quote', () {
    test('once the bus has left', () {
      expect(refundQuote(testTicket(), departure), isNull);
    });

    test('for a booking that is already cancelled', () {
      final cancelled = testTicket(status: BookingStatus.cancelled);
      expect(refundQuote(cancelled, hoursBefore(48)), isNull);
    });
  });
}
