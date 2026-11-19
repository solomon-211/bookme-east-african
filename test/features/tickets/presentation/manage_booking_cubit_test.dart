import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/manage_booking_cubit.dart';

import '../../../helpers/test_ticket.dart';

void main() {
  // testTicket departs 4 Dec 2026 at 21:00 and arrives 5 Dec at 06:30.
  final beforeDeparture = DateTime(2026, 12, 2, 21);
  final afterArrival = DateTime(2026, 12, 5, 12);

  late InMemoryTicketsDataSource source;

  Future<ManageBookingCubit> cubitFor(
    Ticket ticket, {
    required DateTime now,
    Ticket? stored,
  }) async {
    SharedPreferences.setMockInitialValues({});
    source = InMemoryTicketsDataSource(initial: [stored ?? ticket]);
    final repository = TicketsRepositoryImpl(
      source: source,
      cache: TicketCacheDataSource(await SharedPreferences.getInstance()),
      currentUserId: () => 'demo-user',
      clock: () => now,
    );
    return ManageBookingCubit(
      repository: repository,
      ticket: ticket,
      clock: () => now,
    );
  }

  tearDown(() => source.dispose());

  test('starts with the refund for cancelling now', () async {
    final cubit = await cubitFor(testTicket(), now: beforeDeparture);

    expect(cubit.state.quote?.refund, 18000);
    expect(cubit.canRemove, isFalse);
    await cubit.close();
  });

  test('cancel marks the ticket cancelled and keeps the refund', () async {
    final cubit = await cubitFor(testTicket(), now: beforeDeparture);

    await cubit.cancel();

    expect(cubit.state.ticket.isCancelled, isTrue);
    expect(cubit.state.refunded?.refund, 18000);
    expect(cubit.state.quote, isNull);
    expect(cubit.state.message, 'Booking cancelled.');
    expect(source.refunds, hasLength(1));
    await cubit.close();
  });

  test('a failed cancel explains why and changes nothing', () async {
    // Cancelled on another phone after this page was opened.
    final cubit = await cubitFor(
      testTicket(),
      now: beforeDeparture,
      stored: testTicket(status: BookingStatus.cancelled),
    );

    await cubit.cancel();

    expect(cubit.state.status, ManageBookingStatus.idle);
    expect(cubit.state.ticket.isPaid, isTrue);
    expect(cubit.state.message, contains('already cancelled'));
    await cubit.close();
  });

  test('a finished trip can be removed from history', () async {
    final cubit = await cubitFor(testTicket(), now: afterArrival);

    expect(cubit.state.quote, isNull);
    expect(cubit.canRemove, isTrue);
    await cubit.remove();

    expect(cubit.state.status, ManageBookingStatus.removed);
    expect(await source.watchMyTickets().first, isEmpty);
    await cubit.close();
  });
}
