import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/search/data/recent_routes_store.dart';
import 'package:bookme_summative_project/features/search/data/repositories/firestore_search_repository.dart';
import 'package:bookme_summative_project/features/search/data/repositories/firestore_waitlist_repository.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/search_repository.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/waitlist_repository.dart';

/// Builds the repositories Search needs, backed by Firestore. Add the
/// result to the app-level `MultiRepositoryProvider` in `main.dart`:
///
/// ```dart
/// providers: [
///   ...searchRepositoryProviders(prefs: prefs),
///   ...bookingRepositoryProviders(prefs: prefs),
/// ],
/// ```
List<RepositoryProvider<Object>> searchRepositoryProviders({
  required SharedPreferences prefs,
  FirebaseFirestore? firestore,
  FirebaseAuth? auth,
}) {
  final db = firestore ?? FirebaseFirestore.instance;
  final firebaseAuth = auth ?? FirebaseAuth.instance;
  return searchProvidersWith(
    prefs: prefs,
    search: FirestoreSearchRepository(db),
    waitlist: FirestoreWaitlistRepository(
      firestore: db,
      currentUserId: () => firebaseAuth.currentUser?.uid,
    ),
  );
}

/// Same providers over any implementation, e.g. the in-memory ones used by
/// tests and the offline demo.
List<RepositoryProvider<Object>> searchProvidersWith({
  required SharedPreferences prefs,
  required SearchRepository search,
  required WaitlistRepository waitlist,
}) => [
  RepositoryProvider<SearchRepository>.value(value: search),
  RepositoryProvider<WaitlistRepository>.value(value: waitlist),
  RepositoryProvider<RecentRoutesStore>.value(value: RecentRoutesStore(prefs)),
];
