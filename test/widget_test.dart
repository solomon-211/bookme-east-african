import 'package:bookme_summative_project/features/settings/data/settings_local_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

// Walks through the signed-in app (all four tabs) the way a user would.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildTestApp(prefs));
    await tester.pumpAndSettle();
  }

  // Lists only build what is on screen, so scroll an item into view first.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    final verticalList = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: verticalList.first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Account shows the profile and saved items', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    expect(find.text('Moses Mugisha'), findsOneWidget);
    expect(find.text('+250 78 123 4412'), findsOneWidget);
    expect(find.text('EAC ID · Rwanda · Ending 0036'), findsOneWidget);
    expect(find.text('Moses Mugisha · 1 passenger'), findsOneWidget);
    expect(find.text('MTN MoMo · +250 78 123 4412'), findsOneWidget);
  });

  testWidgets('picking a language on Account is saved to the phone', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('language_fr')));
    await tester.pumpAndSettle();

    expect(prefs.getString(SettingsLocalSource.languageKey), 'fr');
  });

  testWidgets('choosing Dark switches the whole app to dark mode', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const Key('theme_dark')));

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(prefs.getString(SettingsLocalSource.themeModeKey), 'dark');
  });

  testWidgets('add a saved passenger from Account', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('passengers_tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_passenger')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('passenger_name')),
      'Amani Uwase',
    );
    await tester.enterText(
      find.byKey(const Key('passenger_phone')),
      '+250788111222',
    );
    await tester.enterText(find.byKey(const Key('passenger_id')), 'PC1234567');
    await tester.tap(find.byKey(const Key('passenger_save')));
    await tester.pumpAndSettle();

    expect(find.text('Amani Uwase'), findsOneWidget);
  });

  testWidgets('an alert link opens Where your money is', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('View escrow timeline →'));

    expect(find.text('Where your money is'), findsOneWidget);
    expect(find.text('18,500 RWF'), findsWidgets);
    expect(find.text('Payment Received (In Escrow)'), findsOneWidget);
  });

  testWidgets('Trust Center lists the verified operators', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Trust Center'));

    expect(find.text('Travel with confidence.'), findsOneWidget);
    expect(find.text('Trinity Express'), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
  });
}
