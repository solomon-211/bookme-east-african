import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/bookme_themes.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/settings/presentation/settings_cubit.dart';
import 'features/settings/presentation/settings_state.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

class BookMeApp extends StatefulWidget {
  const BookMeApp({super.key});

  @override
  State<BookMeApp> createState() => _BookMeAppState();
}

class _BookMeAppState extends State<BookMeApp> {
  late final AuthRepository _repository;
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _repository = AuthRepository();
    // AuthStarted subscribes to Firebase's persisted session, so a user who
    // signed in earlier is restored automatically after an app restart.
    _authBloc = AuthBloc(repository: _repository)..add(const AuthStarted());
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _repository,
      child: BlocProvider.value(
        value: _authBloc,
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (p, c) =>
              (c.errorMessage != null && p.errorMessage != c.errorMessage) ||
              (c.infoMessage != null && p.infoMessage != c.infoMessage),
          listener: (context, state) {
            final text = state.errorMessage ?? state.infoMessage;
            if (text == null) return;
            messengerKey.currentState
              ?..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(text),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          },
          child: BlocBuilder<SettingsCubit, SettingsState>(
            buildWhen: (a, b) => a.themeMode != b.themeMode,
            builder: (context, settings) => MaterialApp.router(
              title: 'BookMe East Africa',
              debugShowCheckedModeBanner: false,
              theme: BookMeThemes.light,
              darkTheme: BookMeThemes.dark,
              themeMode: settings.themeMode,
              scaffoldMessengerKey: messengerKey,
              routerConfig: _router,
            ),
          ),
        ),
      ),
    );
  }
}
