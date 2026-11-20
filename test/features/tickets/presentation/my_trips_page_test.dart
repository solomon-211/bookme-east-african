import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/my_trips_cubit.dart';
import 'package:bookme_summative_project/features/tickets/presentation/cubits/trips_tab_cubit.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/my_trips_page.dart';

import '../../../helpers/test_ticket.dart';
import '../../../helpers/test_trip.dart';

void main() {
  // Two days before testTicket's 4 Dec 2026 21:00 departure.
  final now = DateTime(2026, 12, 2, 21);

  /// Taken on 1 Nov.
  final completed = Ticket(
    booking: testTicket(id: 'booking-old', seat: '1A').booking,
    trip: otherDeparture('trip-old', departure: DateTime(2026, 11, 1, 21)),
  );

  /// Cancelled before its 4 Dec departure.
  final cancelled = testTicket(
    id: 'booking-cancelled',
    status: BookingStatus.cancelled,
  );

  late List<Ticket> shown;
  late int findBus;

  Future<void> openMyTrips(WidgetTester tester, List<Ticket> tickets) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final source = InMemoryTicketsDataSource(initial: tickets);
    addTearDown(source.dispose);
    final repository = TicketsRepositoryImpl(
      source: source,
      cache: TicketCacheDataSource(prefs),
      currentUserId: () => 'demo-user',
      clock: () => now,
    );
    shown = [];
    findBus = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  MyTripsCubit(repository: repository, clock: () => now)
                    ..load(),
            ),
            BlocProvider(create: (_) => TripsTabCubit()),
          ],
          child: MyTripsView(
            actions: MyTripsActions(
              onShowTicket: (_, ticket) => shown.add(ticket),
              onManage: (_, _) {},
              onOpenChecklist: (_, _) {},
              onFindBus: (_) => findBus++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('upcoming trips come first, with recent past trips below', (
    tester,
  ) async {
    await openMyTrips(tester, [testTicket(), completed, cancelled]);

    expect(find.text('Upcoming · 1'), findsOneWidget);
    expect(find.text('Past · 2'), findsOneWidget);
    expect(find.text('Recent past trips'), findsOneWidget);
    expect(find.text('Trinity Express · 1 Nov · Completed'), findsOneWidget);
    expect(find.text('Trinity Express · 4 Dec · Cancelled'), findsOneWidget);
  });

  testWidgets('the Past tab lists past trips and opens their ticket', (
    tester,
  ) async {
    await openMyTrips(tester, [testTicket(), completed, cancelled]);

    await tester.tap(find.text('Past · 2'));
    await tester.pumpAndSettle();

    expect(find.text('Recent past trips'), findsNothing);
    expect(find.text('Kigali → Kampala'), findsNWidgets(2));
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);

    await tester.tap(find.text('Trinity Express · 1 Nov · Completed'));
    expect(shown, [completed]);
  });

  testWidgets('with no trips, both tabs point to Search', (tester) async {
    await openMyTrips(tester, const []);

    expect(find.text('No upcoming trips'), findsOneWidget);
    await tester.tap(find.text('Find a bus'));
    expect(findBus, 1);

    await tester.tap(find.text('Past · 0'));
    await tester.pumpAndSettle();
    expect(find.text('No past trips yet'), findsOneWidget);
  });
}
