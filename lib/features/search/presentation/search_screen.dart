import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bookme_summative_project/features/search/data/recent_routes_store.dart';
import 'package:bookme_summative_project/features/search/domain/entities/city.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/search_repository.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/waitlist_repository.dart';
import 'package:bookme_summative_project/features/search/presentation/bloc/search_bloc.dart';
import 'package:bookme_summative_project/features/search/presentation/cubits/waitlist_cubit.dart';
import 'package:bookme_summative_project/features/search/presentation/pages/search_home_page.dart';
import 'package:bookme_summative_project/features/search/presentation/search_navigation.dart';
import 'package:bookme_summative_project/features/settings/presentation/settings_cubit.dart';

/// The Search tab of the home shell.
///
/// Needs the providers from `searchRepositoryProviders` (and, to book,
/// `bookingRepositoryProviders`) above `MaterialApp`. Works as
/// `const SearchScreen()`; pass [navigation] to connect Tickets and Alerts.
class SearchScreen extends StatelessWidget {
  const SearchScreen({this.navigation = const SearchNavigation(), super.key});

  final SearchNavigation navigation;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        RepositoryProvider<SearchNavigation>.value(value: navigation),
        BlocProvider<SearchBloc>(
          create: (ctx) => SearchBloc(
            repository: ctx.read<SearchRepository>(),
            recentRoutes: _maybeRead<RecentRoutesStore>(ctx),
            defaultOrigin: _defaultOrigin(ctx),
          )..add(const SearchStarted()),
        ),
        BlocProvider<WaitlistCubit>(
          create: (ctx) =>
              WaitlistCubit(repository: ctx.read<WaitlistRepository>())
                ..start(),
        ),
      ],
      child: const SearchHomePage(),
    );
  }

  /// "From" starts on the city chosen in Settings, if any.
  static City? _defaultOrigin(BuildContext context) {
    final settings = _maybeRead<SettingsCubit>(context);
    if (settings == null) return null;
    return Cities.byName(settings.state.settings.defaultDepartureCity);
  }

  static T? _maybeRead<T>(BuildContext context) {
    try {
      return context.read<T>();
    } on Object {
      return null;
    }
  }
}
