import 'package:bloc_test/bloc_test.dart';
import 'package:bookme_summative_project/core/theme/app_theme.dart';
import 'package:bookme_summative_project/core/utils/validators.dart';
import 'package:bookme_summative_project/features/auth/bloc/auth_bloc.dart';
import 'package:bookme_summative_project/features/auth/presentation/phone_sign_in_screen.dart';
import 'package:bookme_summative_project/features/auth/presentation/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;

  setUpAll(() => registerFallbackValue(const AuthStarted()));

  setUp(() {
    bloc = MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<AuthBloc>.value(value: bloc, child: screen),
    ));
  }

  group('WelcomeScreen', () {
    testWidgets('shows the first slide and the sign-in options', (tester) async {
      await pump(tester, const WelcomeScreen());

      expect(find.text('Your bus, booked in minutes'), findsOneWidget);
      expect(find.byKey(const Key('continue_google')), findsOneWidget);
      expect(find.byKey(const Key('continue_phone')), findsOneWidget);
      expect(find.byKey(const Key('continue_email')), findsOneWidget);
    });

    testWidgets('swiping shows the second slide', (tester) async {
      await pump(tester, const WelcomeScreen());

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Pay with mobile money'), findsOneWidget);
    });

    testWidgets('Google and phone buttons are the same size', (tester) async {
      await pump(tester, const WelcomeScreen());

      final google = tester.getSize(find.byKey(const Key('continue_google')));
      final phone = tester.getSize(find.byKey(const Key('continue_phone')));
      expect(google, phone);
      expect(google.height, 52);
    });

    testWidgets('Continue with Google dispatches GoogleSignInRequested',
        (tester) async {
      await pump(tester, const WelcomeScreen());

      await tester.tap(find.byKey(const Key('continue_google')));
      await tester.pump();

      verify(() => bloc.add(const GoogleSignInRequested())).called(1);
    });
  });

  group('PhoneSignInScreen', () {
    testWidgets('defaults to Rwanda (+250)', (tester) async {
      await pump(tester, const PhoneSignInScreen());
      expect(find.byKey(const Key('dial_code')), findsOneWidget);
      expect(find.text('+250'), findsOneWidget);
    });

    testWidgets('the title fits on one line on a narrow phone', (tester) async {
      tester.view.physicalSize = const Size(720, 1600); // 360 logical px wide
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<AuthBloc>.value(
            value: bloc, child: const PhoneSignInScreen()),
      ));

      final title = find.text('Join us via phone number');
      expect(title, findsOneWidget);
      expect(tester.getSize(title).height, lessThan(36));
    });

    testWidgets('Next button and phone field have the same size',
        (tester) async {
      await pump(tester, const PhoneSignInScreen());

      final next = tester.getSize(find.byKey(const Key('phone_next')));
      final field = tester.getSize(find.byKey(const Key('phone_field_box')));
      expect(next, field);
      expect(next.height, 52);
    });

    testWidgets('lists only East African countries', (tester) async {
      await pump(tester, const PhoneSignInScreen());

      await tester.tap(find.byKey(const Key('country_picker')));
      await tester.pumpAndSettle();

      for (final name in [
        'Rwanda', 'Uganda', 'Kenya', 'Tanzania', 'South Sudan', 'Burundi',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('Nigeria'), findsNothing);
    });

    testWidgets('choosing a country changes the dial code', (tester) async {
      await pump(tester, const PhoneSignInScreen());

      await tester.tap(find.byKey(const Key('country_picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('country_Uganda')));
      await tester.pumpAndSettle();

      expect(find.text('+256'), findsOneWidget);
    });

    testWidgets('an invalid number shows an error and sends nothing',
        (tester) async {
      await pump(tester, const PhoneSignInScreen());

      await tester.enterText(find.byKey(const Key('phone_field')), '123');
      await tester.tap(find.byKey(const Key('phone_next')));
      await tester.pump();

      expect(find.text(Validators.phoneInvalid), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('a valid number dispatches an E.164 PhoneNumberSubmitted',
        (tester) async {
      await pump(tester, const PhoneSignInScreen());

      await tester.enterText(
          find.byKey(const Key('phone_field')), '0788 123 456');
      await tester.tap(find.byKey(const Key('phone_next')));
      await tester.pump();

      final captured = verify(() => bloc.add(captureAny())).captured;
      expect(captured.single, const PhoneNumberSubmitted('+250788123456'));
    });
  });
}
