import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/data/datasources/booking_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/booking_firestore_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_booking_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_booking_store.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/in_memory/in_memory_payment_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/payment_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/payment_firestore_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/datasources/payment_preferences_data_source.dart';
import 'package:bookme_summative_project/features/booking/data/gateways/mobile_money_gateway.dart';
import 'package:bookme_summative_project/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:bookme_summative_project/features/booking/data/repositories/payment_repository_impl.dart';
import 'package:bookme_summative_project/features/booking/domain/repositories/booking_repository.dart';
import 'package:bookme_summative_project/features/booking/domain/repositories/payment_repository.dart';

/// Builds the repositories this feature needs, backed by Firestore. Add the
/// result to the app-level `MultiRepositoryProvider` in `main.dart`:
///
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// runApp(MultiRepositoryProvider(
///   providers: [...bookingRepositoryProviders(prefs: prefs), /* others */],
///   child: const BookMeApp(),
/// ));
/// ```
List<RepositoryProvider<Object>> bookingRepositoryProviders({
  required SharedPreferences prefs,
  FirebaseFirestore? firestore,
  FirebaseAuth? auth,
  MobileMoneyGateway? gateway,
}) {
  final db = firestore ?? FirebaseFirestore.instance;
  final firebaseAuth = auth ?? FirebaseAuth.instance;
  return _providers(
    prefs: prefs,
    bookingSource: BookingFirestoreDataSource(
      firestore: db,
      currentUserId: () => firebaseAuth.currentUser?.uid,
    ),
    paymentSource: PaymentFirestoreDataSource(firestore: db),
    gateway: gateway,
  );
}

/// Same repositories, backed by [store] instead of Firestore. Used by the
/// offline demo and by tests.
List<RepositoryProvider<Object>> inMemoryBookingRepositoryProviders({
  required SharedPreferences prefs,
  required InMemoryBookingStore store,
  MobileMoneyGateway? gateway,
}) {
  return _providers(
    prefs: prefs,
    bookingSource: InMemoryBookingDataSource(store),
    paymentSource: InMemoryPaymentDataSource(store),
    gateway: gateway,
  );
}

List<RepositoryProvider<Object>> _providers({
  required SharedPreferences prefs,
  required BookingDataSource bookingSource,
  required PaymentDataSource paymentSource,
  MobileMoneyGateway? gateway,
}) {
  return [
    RepositoryProvider<BookingRepository>.value(
      value: BookingRepositoryImpl(bookingSource),
    ),
    RepositoryProvider<PaymentRepository>.value(
      value: PaymentRepositoryImpl(
        paymentSource: paymentSource,
        bookingSource: bookingSource,
        gateway: gateway ?? MockMobileMoneyGateway(),
        preferences: PaymentPreferencesDataSource(prefs),
      ),
    ),
  ];
}
