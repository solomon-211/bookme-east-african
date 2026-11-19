import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/booking.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/utils/refund_policy.dart';
import 'package:bookme_summative_project/features/tickets/presentation/pages/ticket_page.dart';

import '../../../helpers/test_ticket.dart';

/// Stands in for Firestore: the test pushes the booking (or an error).
class _ManualSource implements TicketsDataSource {
  final StreamController<Ticket> ticket = StreamController<Ticket>();

  @override
  Stream<Ticket> watchTicket(String bookingId) => ticket.stream;

  @override
  Stream<List<Ticket>> watchMyTickets() => const Stream.empty();

  @override
  Future<void> cancelBooking(Ticket ticket, RefundQuote refund) async {}

  @override
  Future<void> deleteBooking(String bookingId) async {}
}

void main() {
  late _ManualSource source;
  late TicketCacheDataSource cache;
  late List<Ticket> checklistOpened;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = TicketCacheDataSource(await SharedPreferences.getInstance());
    source = _ManualSource();
    checklistOpened = [];
  });

  Future<void> pumpTicketPage(WidgetTester tester) async {
    // Tall enough that the whole ticket is laid out without scrolling.
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepositoryProvider<TicketsRepository>.value(
        value: TicketsRepositoryImpl(
          source: source,
          cache: cache,
          currentUserId: () => 'demo-user',
        ),
        child: MaterialApp(
          home: TicketPage(
            bookingId: 'booking-1',
            actions: TicketActions(
              onOpenChecklist: (_, ticket) => checklistOpened.add(ticket),
              onOpenEscrowInfo: (_, _) {},
            ),
          ),
        ),
      ),
    );
  }

  Future<void> deliver(WidgetTester tester, Ticket ticket) async {
    source.ticket.add(ticket);
    await tester.pumpAndSettle();
  }

  testWidgets('a paid ticket shows the boarding QR and its details', (
    tester,
  ) async {
    await pumpTicketPage(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await deliver(tester, testTicket());

    expect(find.text('Seat Booked'), findsOneWidget);
    expect(find.text('Paid 18,500 RWF · Ref BME-7K2Q-4C'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('BME-7K2Q-4C'), findsOneWidget);
    expect(find.text('Moses Mugisha'), findsOneWidget);
    expect(find.text('20:30'), findsOneWidget); // 30 min before 21:00.
    expect(find.text('Save to Phone / Wallet'), findsOneWidget);
  });

  testWidgets('the QR is readable by a screen reader and scanner-sized', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpTicketPage(tester);
    await deliver(tester, testTicket());

    // The label is merged with the reference text under it, so match the
    // part a screen reader announces for the QR itself.
    expect(
      find.bySemanticsLabel(RegExp('Boarding QR code for booking BME-7K2Q-4C')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('qr code')), findsNothing);
    semantics.dispose();
    expect(tester.widget<QrImageView>(find.byType(QrImageView)).size, 158);
    // What the conductor's scanner reads.
    expect(testTicket().qrPayload, 'BOOKME:BME-7K2Q-4C:booking-1');
  });

  testWidgets('a cancelled booking hides the QR and the save button', (
    tester,
  ) async {
    await pumpTicketPage(tester);
    await deliver(tester, testTicket(status: BookingStatus.cancelled));

    expect(find.text('Booking Cancelled'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.textContaining('can no longer be used'), findsOneWidget);
    expect(find.text('Save to Phone / Wallet'), findsNothing);
    expect(find.text('Send SMS Receipt'), findsNothing);
  });

  testWidgets('offline, the saved ticket and QR are still shown', (
    tester,
  ) async {
    await cache.save('demo-user', [testTicket()]);
    await pumpTicketPage(tester);

    source.ticket.addError(Exception('unavailable'));
    await tester.pumpAndSettle();

    expect(find.text('You\'re offline'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('offline with nothing saved offers to try again', (tester) async {
    await pumpTicketPage(tester);

    source.ticket.addError(Exception('unavailable'));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('Save to Phone saves the ticket and confirms', (tester) async {
    await pumpTicketPage(tester);
    await deliver(tester, testTicket());

    await tester.tap(find.text('Save to Phone / Wallet'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ticket saved on this phone'), findsOneWidget);
    expect(cache.load('demo-user'), [testTicket()]);
  });

  testWidgets('the checklist link opens the checklist for this ticket', (
    tester,
  ) async {
    await pumpTicketPage(tester);
    await deliver(tester, testTicket());

    await tester.tap(find.text('View Cross-Border Checklist'));

    expect(checklistOpened, [testTicket()]);
  });
}
