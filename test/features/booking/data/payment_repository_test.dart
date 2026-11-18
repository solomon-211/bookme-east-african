import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_booking_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_booking_store.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_payment_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/payment_preferences_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/gateways/mobile_money_gateway.dart';
import 'package:bookme_summative_project/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:bookme_summative_project/features/booking/data/repositories/payment_repository_impl.dart';
import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/payment_method.dart';

import '../../../helpers/test_trip.dart';

void main() {
  final trip = testTrip;
  late DateTime now;
  late InMemoryBookingStore store;
  late BookingRepositoryImpl bookings;
  late PaymentRepositoryImpl payments;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 11, 16, 12);
    store = InMemoryBookingStore(clock: () => now)
      ..resetSeats('trip-1', ['3A']);
    final bookingSource = InMemoryBookingDataSource(store);
    bookings = BookingRepositoryImpl(bookingSource);
    payments = PaymentRepositoryImpl(
      paymentSource: InMemoryPaymentDataSource(store),
      bookingSource: bookingSource,
      gateway: MockMobileMoneyGateway(
        approvalDelay: const Duration(milliseconds: 20),
      ),
      preferences: PaymentPreferencesDataSource(prefs),
      clock: () => now,
    );
  });

  Future<Payment> finalState(Payment payment) => payments
      .watchPayment(payment.id)
      .firstWhere((p) => p.status.isFinal)
      .timeout(const Duration(seconds: 2));

  test('holding a seat reserves it for 10 minutes', () async {
    final booking = await bookings.holdSeat(trip);

    expect(booking.status, BookingStatus.held);
    expect(booking.seatNumber, '3A');
    expect(booking.totalAmount, 18500);
    expect(booking.holdExpiresAt, now.add(kSeatHoldDuration));
    expect(store.seat('trip-1', '3A')!.isHeldBy(booking.id), isTrue);
  });

  test('a full bus gives a polite failure', () async {
    await bookings.holdSeat(trip);
    expect(
      () => bookings.holdSeat(trip),
      throwsA(
        isA<BookingFailure>().having(
          (f) => f.message,
          'message',
          contains('fully booked'),
        ),
      ),
    );
  });

  test('approved payment marks booking paid and seat booked', () async {
    final booking = await bookings.holdSeat(trip);
    final sent = await payments.startPayment(
      booking: booking,
      method: PaymentMethod.mtnMomo,
      payerPhone: '+250781234412',
    );
    expect(sent.status, PaymentStatus.awaitingApproval);

    final done = await finalState(sent);
    expect(done.status, PaymentStatus.successful);
    expect(done.escrowStatus, EscrowStatus.held);
    expect(store.booking(booking.id)!.status, BookingStatus.paid);
    expect(store.seat('trip-1', '3A')!.status, 'booked');
  });

  test('a number ending in 0000 is declined and the seat stays held', () async {
    final booking = await bookings.holdSeat(trip);
    final sent = await payments.startPayment(
      booking: booking,
      method: PaymentMethod.mtnMomo,
      payerPhone: '+250781230000',
    );

    final done = await finalState(sent);
    expect(done.status, PaymentStatus.failed);
    expect(done.failureReason, contains('declined'));
    expect(store.booking(booking.id)!.status, BookingStatus.held);
  });

  test('a cancelled prompt is never charged, even if approved later', () async {
    final booking = await bookings.holdSeat(trip);
    final sent = await payments.startPayment(
      booking: booking,
      method: PaymentMethod.mtnMomo,
      payerPhone: '+250781234412',
    );
    await payments.cancelPayment(sent.id);
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(store.payment(sent.id)!.status, PaymentStatus.failed);
    expect(store.booking(booking.id)!.status, BookingStatus.held);
  });

  test('a late approval cannot book a seat someone else now holds', () async {
    final first = await bookings.holdSeat(trip);
    final sent = await payments.startPayment(
      booking: first,
      method: PaymentMethod.mtnMomo,
      payerPhone: '+250781234412',
    );

    now = now.add(const Duration(minutes: 11));
    final second = await bookings.holdSeat(trip);
    expect(second.seatNumber, first.seatNumber);

    final done = await finalState(sent);
    expect(done.status, PaymentStatus.failed);
    expect(done.failureReason, contains('hold ended'));
    expect(store.booking(first.id)!.status, BookingStatus.held);
    expect(store.seat('trip-1', '3A')!.isHeldBy(second.id), isTrue);
  });

  test('paying on an expired hold is refused up front', () async {
    final booking = await bookings.holdSeat(trip);
    now = now.add(const Duration(minutes: 11));
    expect(
      () => payments.startPayment(
        booking: booking,
        method: PaymentMethod.card,
        payerPhone: '',
      ),
      throwsA(isA<BookingFailure>()),
    );
  });

  test(
    'requesting payment from someone else extends the hold to 30 min',
    () async {
      final booking = await bookings.holdSeat(trip);
      final sent = await payments.requestPaymentFromOther(
        booking: booking,
        payerPhone: '+250785550198',
      );

      expect(sent.paidByOther, isTrue);
      expect(
        store.booking(booking.id)!.holdExpiresAt,
        now.add(kPaymentRequestDuration),
      );
      expect((await finalState(sent)).status, PaymentStatus.successful);
    },
  );

  test('releasing a paid booking changes nothing', () async {
    final booking = await bookings.holdSeat(trip);
    final sent = await payments.startPayment(
      booking: booking,
      method: PaymentMethod.card,
      payerPhone: '',
    );
    await finalState(sent);

    await bookings.releaseHold(booking);
    expect(store.booking(booking.id)!.status, BookingStatus.paid);
    expect(store.seat('trip-1', '3A')!.status, 'booked');
  });

  test('last method and phone are remembered', () async {
    await payments.saveLastPreference(PaymentMethod.mpesa, '+254712345678');
    final saved = await payments.loadLastPreference();
    expect(saved!.method, PaymentMethod.mpesa);
    expect(saved.phone, '+254712345678');
  });
}
