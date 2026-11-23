import 'package:bookme_summative_project/core/theme/bookme_themes.dart';
import 'package:bookme_summative_project/core/utils/validators.dart';
import 'package:bookme_summative_project/features/auth/bloc/auth_bloc.dart';
import 'package:bookme_summative_project/features/auth/data/auth_repository.dart';
import 'package:bookme_summative_project/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() => repository = _MockAuthRepository());

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(repository: repository),
        child: MaterialApp(
          theme: BookMeThemes.light,
          home: const LoginScreen(),
        ),
      ),
    );
  }

  testWidgets('empty form shows polite errors and never calls Firebase', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pump();

    expect(find.text(Validators.emailRequired), findsOneWidget);
    expect(find.text(Validators.passwordRequired), findsOneWidget);
    verifyNever(() => repository.signInWithEmail(any(), any()));
  });

  testWidgets('valid details sign in with the trimmed email', (tester) async {
    when(
      () => repository.signInWithEmail(any(), any()),
    ).thenAnswer((_) async {});
    await pumpLogin(tester);

    await tester.enterText(
      find.byKey(const Key('email_field')),
      ' moses@example.com ',
    );
    await tester.enterText(find.byKey(const Key('password_field')), 'secret1');
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pump();

    verify(
      () => repository.signInWithEmail('moses@example.com', 'secret1'),
    ).called(1);
  });

  testWidgets('switching to register asks for a name and a strong password', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.byKey(const Key('toggle_mode')));
    await tester.pump();
    expect(find.byKey(const Key('name_field')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('password_field')), 'short');
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pump();

    expect(find.text(Validators.nameRequired), findsOneWidget);
    expect(find.text(Validators.passwordTooShort), findsOneWidget);
  });
}
