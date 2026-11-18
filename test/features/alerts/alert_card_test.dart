import 'package:bookme_summative_project/core/theme/bookme_themes.dart';
import 'package:bookme_summative_project/features/alerts/data/alerts_repository_impl.dart';
import 'package:bookme_summative_project/features/alerts/domain/alerts_repository.dart';
import 'package:bookme_summative_project/features/alerts/domain/app_alert.dart';
import 'package:bookme_summative_project/features/alerts/presentation/alert_card.dart';
import 'package:bookme_summative_project/features/alerts/presentation/alerts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 10, 2, 18);

Widget wrap(Widget child) => MaterialApp(
  theme: BookMeThemes.light,
  home: Scaffold(body: child),
);

void main() {
  group('AlertCard', () {
    final delay = InMemoryAlertsRepository.demoAlerts(now).first;

    testWidgets('shows title, body, time and the action link', (tester) async {
      await tester.pumpWidget(wrap(AlertCard(alert: delay, timeLabel: 'Now')));

      expect(
        find.text('Delay over 2 hours · Refund triggered'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Your full 18,500 RWF refund'),
        findsOneWidget,
      );
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('Track automatic refund →'), findsOneWidget);
    });

    testWidgets('tapping the link calls onAction', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          AlertCard(
            alert: delay,
            timeLabel: 'Now',
            onAction: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Track automatic refund →'));
      expect(tapped, isTrue);
    });

    testWidgets('no link when the alert has no action', (tester) async {
      final plain = AppAlert(
        id: 'x',
        kind: AlertKind.paymentProtected,
        title: 'Payment protected',
        body: 'Held in escrow.',
        createdAt: now,
      );
      await tester.pumpWidget(wrap(AlertCard(alert: plain, timeLabel: 'Now')));

      expect(find.textContaining('→'), findsNothing);
    });
  });

  group('AlertsScreen', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      // Tall enough to show every card without scrolling.
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        RepositoryProvider<AlertsRepository>.value(
          value: InMemoryAlertsRepository(
            InMemoryAlertsRepository.demoAlerts(now),
          ),
          child: MaterialApp(
            theme: BookMeThemes.light,
            home: AlertsScreen(clock: () => now),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists all five alerts with relative times', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('12m ago'), findsOneWidget);
      expect(find.text('2h ago'), findsOneWidget);
      expect(find.text('Earlier today'), findsOneWidget);
    });

    testWidgets('filter chips narrow the list', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('filter_payments')));
      await tester.pumpAndSettle();

      expect(find.text('Payment protected in escrow'), findsOneWidget);
      expect(find.text('A seat opened up'), findsNothing);

      await tester.tap(find.byKey(const Key('filter_seatAlerts')));
      await tester.pumpAndSettle();

      expect(find.text('A seat opened up'), findsOneWidget);
      expect(find.text('Payment protected in escrow'), findsNothing);
    });

    testWidgets('swiping deletes an alert and Undo brings it back', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.drag(find.text('A seat opened up'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(find.text('A seat opened up'), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('A seat opened up'), findsOneWidget);
    });
  });

  group('alertTimeLabel', () {
    test('covers each time bucket', () {
      expect(alertTimeLabel(now, now), 'Now');
      expect(
        alertTimeLabel(now.subtract(const Duration(minutes: 12)), now),
        '12m ago',
      );
      expect(
        alertTimeLabel(now.subtract(const Duration(hours: 2)), now),
        '2h ago',
      );
      expect(
        alertTimeLabel(now.subtract(const Duration(hours: 6)), now),
        'Earlier today',
      );
      expect(
        alertTimeLabel(now.subtract(const Duration(days: 1)), now),
        'Yesterday',
      );
      expect(alertTimeLabel(DateTime(2026, 9, 14), now), '14 Sep');
    });
  });

  test('each alert kind belongs to the right filter chip', () {
    expect(AlertKind.delay.filter, AlertFilter.trips);
    expect(AlertKind.seatOpened.filter, AlertFilter.seatAlerts);
    expect(AlertKind.priceWatch.filter, AlertFilter.seatAlerts);
    expect(AlertKind.refundReceived.filter, AlertFilter.payments);
  });
}
