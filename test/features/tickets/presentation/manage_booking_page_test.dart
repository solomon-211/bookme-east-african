import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/manage_booking_page.dart';

import '../../../helpers/test_ticket.dart';

void main() {
  // testTicket departs 4 Dec 2026 at 21:00 and arrives 5 Dec at 06:30.
  final beforeDeparture = DateTime(2026, 12, 2, 21);
  final afterArrival = DateTime(2026, 12, 5, 12);

  late InMemoryTicketsDataSource source;
  late List<Ticket> changeDateOpened;

  /// Opens Manage Booking from a plain home screen, so closing it can be
  /// checked.
  Future<void> openManage(WidgetTester tester, {required DateTime now}) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    source = InMemoryTicketsDataSource(initial: [testTicket()]);
    addTearDown(source.dispose);
    changeDateOpened = [];

    await tester.pumpWidget(
      RepositoryProvider<TicketsRepository>.value(
        value: TicketsRepositoryImpl(
          source: source,
          cache: TicketCacheDataSource(prefs),
          currentUserId: () => 'demo-user',
          clock: () => now,
        ),
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ManageBookingPage(
                      ticket: testTicket(),
                      clock: () => now,
                      actions: ManageBookingActions(
                        onChangeDate: (_, t) => changeDateOpened.add(t),
                        onOpenEscrowInfo: (_, _) {},
                      ),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the refund before cancelling', (tester) async {
    await openManage(tester, now: beforeDeparture);

    expect(find.text('Manage booking'), findsOneWidget);
    expect(find.text('BME-7K2Q-4C · Moses Mugisha'), findsOneWidget);
    expect(find.text('18,500 RWF'), findsOneWidget); // Original payment.
    expect(find.text('18,000 RWF'), findsOneWidget); // You get back.
    expect(find.text('Remove from History'), findsNothing);
  });

  testWidgets('cancelling asks first, then shows the refund', (tester) async {
    await openManage(tester, now: beforeDeparture);

    await tester.tap(find.text('Cancel / Request Refund'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel this booking?'), findsOneWidget);
    expect(find.textContaining('seat 4C is released'), findsOneWidget);

    await tester.tap(find.text('Cancel booking'));
    await tester.pumpAndSettle();

    expect(find.text('Booking cancelled'), findsOneWidget);
    expect(find.textContaining('18,000 RWF is on its way'), findsOneWidget);
    expect(find.text('Cancel / Request Refund'), findsNothing);
    expect(find.text('Change date / time'), findsNothing);
    expect(source.refunds['booking-1']?.refund, 18000);
  });

  testWidgets('"Keep booking" leaves the booking as it was', (tester) async {
    await openManage(tester, now: beforeDeparture);

    await tester.tap(find.text('Cancel / Request Refund'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep booking'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel / Request Refund'), findsOneWidget);
    expect(source.refunds, isEmpty);
  });

  testWidgets('change date opens the departure picker', (tester) async {
    await openManage(tester, now: beforeDeparture);

    await tester.tap(find.text('Change date / time'));

    expect(changeDateOpened, [testTicket()]);
  });

  testWidgets('a finished trip can be removed from history', (tester) async {
    await openManage(tester, now: afterArrival);

    expect(find.text('Cancel / Request Refund'), findsNothing);
    expect(find.text('Change date / time'), findsNothing);

    await tester.tap(find.text('Remove from History'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Manage booking'), findsNothing); // Page closed.
    expect(find.text('Trip removed from your history.'), findsOneWidget);
    // Streams need real async; widget tests run on a fake clock.
    final left = await tester.runAsync(() => source.watchMyTickets().first);
    expect(left, isEmpty);
  });
}
