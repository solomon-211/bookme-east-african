import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_booking_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_booking_store.dart';
import 'package:bookme_summative_project/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/booking/presentation/cubits/seat_hold_cubit.dart';

import '../../../helpers/test_trip.dart';

void main() {
  final trip = testTrip;
  late DateTime now;
  late InMemoryBookingStore store;
  late StreamController<DateTime> ticks;
  late SeatHoldCubit cubit;

  setUp(() {
    now = DateTime(2026, 11, 16, 12);
    store = InMemoryBookingStore(clock: () => now)
      ..resetSeats(trip.tripId, ['3A']);
    ticks = StreamController<DateTime>();
    cubit = SeatHoldCubit(
      repository: BookingRepositoryImpl(InMemoryBookingDataSource(store)),
      ticker: () => ticks.stream,
      clock: () => now,
    );
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
    // Not awaited: close() on a stream nobody listened to never completes
    // (the "full bus" test never starts the ticker).
    unawaited(ticks.close());
  });

  test('counts down and releases the seat when the hold expires', () async {
    await cubit.start(trip);
    expect(cubit.state.status, SeatHoldStatus.active);
    expect(cubit.state.remaining, kSeatHoldDuration);

    ticks.add(now.add(const Duration(minutes: 4)));
    await pumpEventQueue();
    expect(cubit.state.remaining, const Duration(minutes: 6));
    expect(cubit.state.progress, closeTo(0.6, 0.001));

    ticks.add(now.add(const Duration(minutes: 10, seconds: 1)));
    await pumpEventQueue();
    expect(cubit.state.status, SeatHoldStatus.expired);

    final booking = cubit.state.booking!;
    expect(store.booking(booking.id)!.status, BookingStatus.expired);
    expect(store.seat(trip.tripId, '3A')!.status, 'available');
  });

  test('leaving the flow gives the seat back straight away', () async {
    await cubit.start(trip);
    final booking = cubit.state.booking!;

    await cubit.close();
    await pumpEventQueue();
    expect(store.booking(booking.id)!.status, BookingStatus.expired);
    expect(store.seat(trip.tripId, '3A')!.status, 'available');
  });

  test('a full bus shows the failure state', () async {
    store.seat(trip.tripId, '3A')!.status = 'booked';
    await cubit.start(trip);
    expect(cubit.state.status, SeatHoldStatus.failure);
    expect(cubit.state.message, contains('fully booked'));
  });
}
