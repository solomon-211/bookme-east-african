import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/domain/entities/trip_summary.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';
import 'package:bookme_summative_project/features/tickets/presentation/tickets_screen.dart';
import 'package:bookme_summative_project/features/tickets/tickets_injection.dart';

import '../../../helpers/test_ticket.dart';

/// The test ticket moved to two days from now, so it is always upcoming.
Ticket _upcomingTicket() {
  final base = testTicket();
  final departure = DateTime.now().add(const Duration(days: 2));
  final t = base.trip;
  return Ticket(
    booking: base.booking,
    trip: TripSummary(
      tripId: t.tripId,
      operatorName: t.operatorName,
      fromCode: t.fromCode,
      fromStation: t.fromStation,
      toCode: t.toCode,
      toStation: t.toStation,
      departure: departure,
      arrival: departure.add(const Duration(hours: 9, minutes: 30)),
      durationLabel: t.durationLabel,
      baseFare: t.baseFare,
      serviceFee: t.serviceFee,
    ),
  );
}

void main() {
  Future<void> pumpTickets(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final source = InMemoryTicketsDataSource(initial: [_upcomingTicket()]);
    addTearDown(source.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: inMemoryTicketsRepositoryProviders(
          prefs: prefs,
          source: source,
        ),
        child: const MaterialApp(home: TicketsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Show Offline QR opens the offline ticket', (tester) async {
    await pumpTickets(tester);

    await tester.tap(find.text('Show Offline QR'));
    await tester.pumpAndSettle();

    expect(find.text('Offline Ticket'), findsOneWidget);
    expect(find.text('BME-7K2Q-4C'), findsOneWidget);
  });

  testWidgets('the checklist link opens Ready for Journey', (tester) async {
    await pumpTickets(tester);

    await tester.tap(find.textContaining('View full checklist'));
    await tester.pumpAndSettle();

    expect(find.text('Ready for your journey?'), findsOneWidget);
    expect(find.text('Cross-border checklist'), findsOneWidget);
  });
}
