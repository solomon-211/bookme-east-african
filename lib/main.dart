import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo/trust_account_demo_app.dart';
import 'features/account/trust_account_injection.dart';
import 'features/settings/data/settings_local_source.dart';
import 'features/settings/data/settings_repository_impl.dart';
import 'features/settings/presentation/settings_cubit.dart';

// Temporary entry point for the Trust & Account branch. Uses the in-memory
// repositories (Figma sample data) so it runs without Firebase. When this
// is merged with Auth's main.dart, keep Firebase.initializeApp and swap
// in trustAccountRepositoryProviders(prefs: prefs).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Read saved settings before the first frame, so the right theme shows
  // straight away instead of flashing the default.
  final settings = await SettingsRepositoryImpl(SettingsLocalSource(prefs))
      .loadSettings();

  runApp(
    MultiRepositoryProvider(
      providers: inMemoryTrustAccountRepositoryProviders(prefs: prefs),
      child: BlocProvider(
        create: (context) => SettingsCubit(context.read(), initial: settings),
        child: const TrustAccountDemoApp(),
      ),
    ),
  );

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BookMeApp());
}
