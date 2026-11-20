import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../alerts/data/alerts_repository_impl.dart';
import '../alerts/domain/alerts_repository.dart';
import '../escrow/data/escrow_repository_impl.dart';
import '../escrow/domain/escrow_repository.dart';
import '../settings/data/settings_local_source.dart';
import '../settings/data/settings_repository_impl.dart';
import '../settings/domain/settings_repository.dart';
import '../trust/data/trust_repository_impl.dart';
import '../trust/domain/trust_repository.dart';
import 'data/account_repository_impl.dart';
import 'data/in_memory_account_repository.dart';
import 'domain/account_repository.dart';

// Repositories for Trust & Account (Account, Alerts, Escrow, Trust Center,
// Settings). Add them to the app's MultiRepositoryProvider in main.dart:
//
//   final prefs = await SharedPreferences.getInstance();
//   runApp(MultiRepositoryProvider(
//     providers: [
//       ...bookingRepositoryProviders(prefs: prefs),
//       ...trustAccountRepositoryProviders(prefs: prefs),
//     ],
//     child: const BookMeApp(),
//   ));
List<RepositoryProvider<Object>> trustAccountRepositoryProviders({
  required SharedPreferences prefs,
  FirebaseFirestore? firestore,
  FirebaseAuth? auth,
}) {
  final db = firestore ?? FirebaseFirestore.instance;
  final firebaseAuth = auth ?? FirebaseAuth.instance;
  String? uid() => firebaseAuth.currentUser?.uid;

  return [
    _settings(prefs),
    RepositoryProvider<AccountRepository>.value(
      value: AccountRepositoryImpl(firestore: db, auth: firebaseAuth),
    ),
    RepositoryProvider<AlertsRepository>.value(
      value: AlertsRepositoryImpl(firestore: db, currentUserId: uid),
    ),
    RepositoryProvider<EscrowRepository>.value(
      value: EscrowRepositoryImpl(firestore: db, currentUserId: uid),
    ),
    RepositoryProvider<TrustRepository>.value(value: TrustRepositoryImpl(db)),
  ];
}

// Same repositories filled with the Figma sample data, for running the
// screens without Firebase and for widget tests.
List<RepositoryProvider<Object>> inMemoryTrustAccountRepositoryProviders({
  required SharedPreferences prefs,
  DateTime Function() clock = DateTime.now,
}) {
  return [
    _settings(prefs),
    RepositoryProvider<AccountRepository>.value(
      value: InMemoryAccountRepository.demo(),
    ),
    RepositoryProvider<AlertsRepository>.value(
      value: InMemoryAlertsRepository(
        InMemoryAlertsRepository.demoAlerts(clock()),
      ),
    ),
    RepositoryProvider<EscrowRepository>.value(
      value: InMemoryEscrowRepository(),
    ),
    RepositoryProvider<TrustRepository>.value(value: InMemoryTrustRepository()),
  ];
}

RepositoryProvider<SettingsRepository> _settings(SharedPreferences prefs) =>
    RepositoryProvider<SettingsRepository>.value(
      value: SettingsRepositoryImpl(SettingsLocalSource(prefs)),
    );
