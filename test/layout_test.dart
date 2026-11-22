import 'package:bookme_summative_project/core/theme/bookme_themes.dart';
import 'package:bookme_summative_project/features/auth/bloc/auth_bloc.dart';
import 'package:bookme_summative_project/features/auth/data/auth_repository.dart';
import 'package:bookme_summative_project/features/auth/presentation/otp_screen.dart';
import 'package:bookme_summative_project/features/auth/presentation/phone_sign_in_screen.dart';
import 'package:bookme_summative_project/features/auth/presentation/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/app_harness.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

// Every main screen must lay out without overflow on a small 5" phone, a
// large 6.7" phone and in landscape. Flutter reports an overflow as an
// error, which fails the test.
const _screens = {
  'small phone (320x568)': Size(320, 568),
  'large phone (430x932)': Size(430, 932),
  'landscape (900x400)': Size(900, 400),
};

void main() {
  Future<void> useSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final MapEntry(key: name, value: size) in _screens.entries) {
    testWidgets('signed-in tabs fit on a $name', (tester) async {
      await useSize(tester, size);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(buildTestApp(prefs));
      await tester.pumpAndSettle();

      for (final tab in ['My Trips', 'Alerts', 'Account', 'Search']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('sign-in screens fit on a $name', (tester) async {
      await useSize(tester, size);

      for (final screen in const [
        WelcomeScreen(),
        PhoneSignInScreen(),
        OtpScreen(),
      ]) {
        await tester.pumpWidget(
          BlocProvider(
            create: (_) => AuthBloc(repository: _MockAuthRepository()),
            child: MaterialApp(theme: BookMeThemes.light, home: screen),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Stop the OTP resend countdown before the test ends.
      await tester.pumpWidget(const SizedBox());
    });
  }
}
