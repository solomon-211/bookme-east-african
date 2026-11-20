import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/tickets/data/datasources/in_memory/in_memory_tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_firestore_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/journey_checklist_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/journey_checklist_repository.dart';
import 'package:bookme_summative_project/features/tickets/domain/repositories/tickets_repository.dart';

/// Builds the repositories Tickets & Trips needs, backed by Firestore. Add
/// the result to the app-level `MultiRepositoryProvider` in `main.dart`,
/// above `MaterialApp` so every pushed screen can read them:
///
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// runApp(MultiRepositoryProvider(
///   providers: [
///     ...bookingRepositoryProviders(prefs: prefs),
///     ...ticketsRepositoryProviders(prefs: prefs),
///   ],
///   child: const BookMeApp(),
/// ));
/// ```
List<RepositoryProvider<Object>> ticketsRepositoryProviders({
  required SharedPreferences prefs,
  FirebaseFirestore? firestore,
  FirebaseAuth? auth,
}) {
  final firebaseAuth = auth ?? FirebaseAuth.instance;
  String? currentUserId() => firebaseAuth.currentUser?.uid;
  return _providers(
    prefs: prefs,
    source: TicketsFirestoreDataSource(
      firestore: firestore ?? FirebaseFirestore.instance,
      currentUserId: currentUserId,
    ),
    currentUserId: currentUserId,
  );
}

/// Same repositories, backed by [source] instead of Firestore. Used by the
/// offline demo and by tests.
List<RepositoryProvider<Object>> inMemoryTicketsRepositoryProviders({
  required SharedPreferences prefs,
  required InMemoryTicketsDataSource source,
}) {
  return _providers(
    prefs: prefs,
    source: source,
    currentUserId: () => source.userId,
  );
}

List<RepositoryProvider<Object>> _providers({
  required SharedPreferences prefs,
  required TicketsDataSource source,
  required String? Function() currentUserId,
}) {
  return [
    RepositoryProvider<TicketsRepository>.value(
      value: TicketsRepositoryImpl(
        source: source,
        cache: TicketCacheDataSource(prefs),
        currentUserId: currentUserId,
      ),
    ),
    RepositoryProvider<JourneyChecklistRepository>.value(
      value: JourneyChecklistRepositoryImpl(prefs),
    ),
  ];
}
