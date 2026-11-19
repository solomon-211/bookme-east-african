import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/change_date_page.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/manage_booking_page.dart';

import '../../../helpers/test_ticket.dart';
import '../../../helpers/test_trip.dart';

void main() {
  // Two days before testTicket's 4 Dec 2026 21:00 departure.
  final now = DateTime(2026, 12, 2, 21);

  final cheaper = otherDeparture(
    'trip-cheaper',
    departure: DateTime(2026, 12, 5, 7),
    baseFare: 15000,
  );
  final dearer = otherDeparture(
    'trip-dearer',
    departure: DateTime(2026, 12, 7, 21),
    baseFare: 20000,
  );

  late InMemoryTicketsDataSource source;

  /// Opens Manage Booking with Change date wired to the real picker, as
  /// `TicketsNavigation` does.
  Future<void> openManage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    source = InMemoryTicketsDataSource(
      initial: [testTicket()],
      trips: [testTrip, dearer, cheaper],
      freeSeats: {
        'trip-cheaper': ['2B'],
        'trip-dearer': ['1A'],
      },
    );
    addTearDown(source.dispose);

    await tester.pumpWidget(
      RepositoryProvider<TicketsRepository>.value(
        value: TicketsRepositoryImpl(
          source: source,
          cache: TicketCacheDataSource(prefs),
          currentUserId: () => 'demo-user',
          clock: () => now,
        ),
        child: MaterialApp(
          home: ManageBookingPage(
            ticket: testTicket(),
            clock: () => now,
            actions: ManageBookingActions(
              onChangeDate: (context, ticket) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ChangeDatePage(ticket: ticket, clock: () => now),
                ),
              ),
              onOpenEscrowInfo: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Change date / time'));
    await tester.pumpAndSettle();
  }

  testWidgets('lists departures with the fare difference', (tester) async {
    await openManage(tester);

    expect(find.text('Sat 5 Dec, 07:00'), findsOneWidget);
    expect(find.text('3,000 RWF back'), findsOneWidget);
    expect(find.text('Mon 7 Dec, 21:00'), findsOneWidget);
    expect(find.text('+2,000 RWF · not yet'), findsOneWidget);
    expect(find.text('Pick a departure'), findsOneWidget);
  });

  testWidgets('a dearer departure cannot be picked', (tester) async {
    await openManage(tester);

    await tester.tap(find.text('Mon 7 Dec, 21:00'));
    await tester.pump();

    expect(find.text('Pick a departure'), findsOneWidget);
  });

  testWidgets('moving asks first, then updates Manage Booking', (tester) async {
    await openManage(tester);

    await tester.tap(find.text('Sat 5 Dec, 07:00'));
    await tester.pump();
    await tester.tap(find.text('Move to Sat 5 Dec, 07:00'));
    await tester.pumpAndSettle();
    expect(find.text('Move this booking?'), findsOneWidget);
    expect(find.textContaining('3,000 RWF goes back'), findsOneWidget);

    await tester.tap(find.text('Move booking'));
    await tester.pumpAndSettle();

    // Back on Manage Booking, now showing the new departure and seat.
    expect(find.text('Manage booking'), findsOneWidget);
    expect(find.textContaining('Seat 2B'), findsWidgets);
    expect(find.text('15,500 RWF'), findsOneWidget); // New original payment.
    expect(source.changes.single.refund, 3000);
  });

  testWidgets('"Keep current" leaves the booking as it was', (tester) async {
    await openManage(tester);

    await tester.tap(find.text('Sat 5 Dec, 07:00'));
    await tester.pump();
    await tester.tap(find.text('Move to Sat 5 Dec, 07:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep current'));
    await tester.pumpAndSettle();

    expect(find.text('Change date / time'), findsOneWidget);
    expect(source.changes, isEmpty);
  });
}
