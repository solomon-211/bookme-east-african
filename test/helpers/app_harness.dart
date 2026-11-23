import 'package:bookme_summative_project/core/theme/bookme_themes.dart';
import 'package:bookme_summative_project/features/account/trust_account_injection.dart';
import 'package:bookme_summative_project/features/booking/booking_injection.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_booking_store.dart';
import 'package:bookme_summative_project/features/home/home_shell.dart';
import 'package:bookme_summative_project/features/search/data/repositories/in_memory_search_repositories.dart';
import 'package:bookme_summative_project/features/search/search_injection.dart';
import 'package:bookme_summative_project/features/settings/presentation/settings_cubit.dart';
import 'package:bookme_summative_project/features/settings/presentation/settings_state.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/tickets_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The real signed-in app (HomeShell with all four tabs) over in-memory
// data, so widget tests can walk through it without Firebase.
Widget buildTestApp(SharedPreferences prefs, {DateTime? now}) {
  final start = now ?? DateTime.now();

  return MultiRepositoryProvider(
    providers: [
      ...searchProvidersWith(
        prefs: prefs,
        search: InMemorySearchRepository.seeded(start),
        waitlist: InMemoryWaitlistRepository(),
      ),
      ...inMemoryBookingRepositoryProviders(
        prefs: prefs,
        store: InMemoryBookingStore(),
      ),
      ...inMemoryTicketsRepositoryProviders(
        prefs: prefs,
        source: InMemoryTicketsDataSource(),
      ),
      ...inMemoryTrustAccountRepositoryProviders(prefs: prefs),
    ],
    child: BlocProvider(
      create: (context) => SettingsCubit(context.read())..load(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (a, b) => a.themeMode != b.themeMode,
        builder: (context, settings) => MaterialApp(
          theme: BookMeThemes.light,
          darkTheme: BookMeThemes.dark,
          themeMode: settings.themeMode,
          home: const HomeShell(),
        ),
      ),
    ),
  );
}
