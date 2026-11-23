import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/account/trust_account_injection.dart';
import 'features/booking/booking_injection.dart';
import 'features/search/search_injection.dart';
import 'features/settings/data/settings_local_source.dart';
import 'features/settings/data/settings_repository_impl.dart';
import 'features/settings/presentation/settings_cubit.dart';
import 'features/tickets/tickets_injection.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();

  // Read saved settings before the first frame so the right theme shows
  // straight away instead of flashing the default.
  final settings = await SettingsRepositoryImpl(
    SettingsLocalSource(prefs),
  ).loadSettings();

  runApp(
    MultiRepositoryProvider(
      // Every feature's repositories, above MaterialApp so pushed
      // screens can read them too.
      providers: [
        ...searchRepositoryProviders(prefs: prefs),
        ...bookingRepositoryProviders(prefs: prefs),
        ...ticketsRepositoryProviders(prefs: prefs),
        ...trustAccountRepositoryProviders(prefs: prefs),
      ],
      child: BlocProvider(
        create: (context) => SettingsCubit(context.read(), initial: settings),
        child: const BookMeApp(),
      ),
    ),
  );
}
