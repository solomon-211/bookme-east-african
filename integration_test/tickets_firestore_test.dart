// Runs the Tickets & Trips Firestore code against the Firebase emulators,
// with the team's security rules loaded. See integration_test/README.md.
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/booking/domain/booking_failure.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/ticket_cache_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/datasources/tickets_firestore_data_source.dart';
import 'package:bookme_summative_project/features/tickets/data/repositories/tickets_repository_impl.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

const _project = 'demo-bookme';
const _host = '127.0.0.1';
const _firestorePort = 8080;
const _authPort = 9099;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseFirestore db;
  late TicketsRepositoryImpl repository;
  late String uid;

  // Trips are relative to now so the refund rules give a known answer:
  // more than 24 hours ahead, a voluntary cancel refunds the fare.
  final clock = DateTime.now();
  final now = DateTime(clock.year, clock.month, clock.day, clock.hour);
  final booked = now.add(const Duration(days: 3));
  final cheaper = now.add(const Duration(days: 4));
  final dearer = now.add(const Duration(days: 5));

  setUpAll(() async {
    await Firebase.initializeApp(
      // The emulators accept any values, but the Apple SDK aborts unless
      // the key and app id are shaped like real ones.
      options: const FirebaseOptions(
        apiKey: 'AIzaDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD',
        appId: '1:123456789000:ios:0123456789abcdef',
        messagingSenderId: '123456789000',
        projectId: _project,
      ),
    );
    db = FirebaseFirestore.instance
      ..useFirestoreEmulator(_host, _firestorePort)
      ..settings = const Settings(persistenceEnabled: false);
    await FirebaseAuth.instance.useAuthEmulator(_host, _authPort);
  });

  setUp(() async {
    await _clearFirestore();
    await FirebaseAuth.instance.signOut();
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email:
              'traveller${now.microsecondsSinceEpoch}'
              '${DateTime.now().microsecond}@bookme.test',
          password: 'password123',
        );
    uid = credential.user!.uid;

    // What Search and Booking & Payment leave behind after a paid booking.
    await _seed('trips/trip-1', _trip(booked, baseFare: 18000));
    await _seed('trips/trip-cheaper', _trip(cheaper, baseFare: 15000));
    await _seed('trips/trip-dearer', _trip(dearer, baseFare: 20000));
    await _seed('trips/trip-1/seats/4C', _seat('booked', uid, 'booking-1'));
    await _seed('trips/trip-cheaper/seats/2B', _seat('available'));
    await _seed('trips/trip-dearer/seats/1A', _seat('available'));
    await _seed('bookings/booking-1', {
      'userId': uid,
      'reference': 'BME-7K2Q-4C',
      'tripId': 'trip-1',
      'seatNumber': '4C',
      'status': 'paid',
      'holdExpiresAt': now,
      'totalAmount': 18500,
      'currency': 'RWF',
      'createdAt': now,
    });

    SharedPreferences.setMockInitialValues({});
    repository = TicketsRepositoryImpl(
      source: TicketsFirestoreDataSource(
        firestore: db,
        currentUserId: () => FirebaseAuth.instance.currentUser?.uid,
      ),
      cache: TicketCacheDataSource(await SharedPreferences.getInstance()),
      currentUserId: () => FirebaseAuth.instance.currentUser?.uid,
    );
  });

  Future<Ticket> myTicket() async =>
      (await repository.watchMyTickets().first).single;

  Future<Map<String, dynamic>?> read(String path) async =>
      (await db.doc(path).get()).data();

  testWidgets('My Trips shows the paid booking', (tester) async {
    final ticket = await myTicket();

    expect(ticket.booking.reference, 'BME-7K2Q-4C');
    expect(ticket.trip.departure, booked);
    expect(ticket.isPaid, isTrue);
  });

  testWidgets('cancel records the refund and frees the seat', (tester) async {
    final refund = await repository.cancelBooking(await myTicket());

    expect(refund.refund, 18000);
    final booking = (await read('bookings/booking-1'))!;
    expect(booking['status'], 'cancelled');
    expect(booking['refundAmount'], 18000);
    expect(booking['refundReason'], 'voluntary');
    expect(booking['cancelledAt'], isA<Timestamp>());
    final seat = (await read('trips/trip-1/seats/4C'))!;
    expect(seat['status'], 'available');
    expect(seat['bookingId'], isNull);
  });

  testWidgets('a second cancel is refused', (tester) async {
    final ticket = await myTicket();
    await repository.cancelBooking(ticket);

    await expectLater(
      repository.cancelBooking(ticket),
      throwsA(isA<BookingFailure>()),
    );
  });

  testWidgets('change date lists the other departures', (tester) async {
    final trips = await repository.alternativeTrips(await myTicket());

    expect(trips.map((t) => t.tripId), ['trip-cheaper', 'trip-dearer']);
  });

  testWidgets('change date moves the booking and both seats', (tester) async {
    final ticket = await myTicket();
    final target = (await repository.alternativeTrips(ticket)).first;

    final changed = await repository.changeTrip(ticket, target);

    expect(changed.booking.seatNumber, '2B');
    final booking = (await read('bookings/booking-1'))!;
    expect(booking['tripId'], 'trip-cheaper');
    expect(booking['seatNumber'], '2B');
    expect(booking['totalAmount'], 15500);
    expect(booking['reference'], 'BME-7K2Q-4C');
    final history = booking['changeHistory'] as List<dynamic>;
    expect(history.single['refundAmount'], 3000);
    expect((await read('trips/trip-1/seats/4C'))!['status'], 'available');
    final newSeat = (await read('trips/trip-cheaper/seats/2B'))!;
    expect(newSeat['status'], 'booked');
    expect(newSeat['bookingId'], 'booking-1');
  });

  testWidgets('a cancelled trip can be removed from history', (tester) async {
    final ticket = await myTicket();
    await repository.cancelBooking(ticket);
    // Transactions don't update the local cache, so a new listener first
    // replays the cached paid copy, then the server's cancelled one.
    final cancelled = (await repository.watchMyTickets().firstWhere(
      (tickets) => tickets.single.isCancelled,
    )).single;

    await repository.removeFromHistory(cancelled);

    // Reading the deleted document itself is refused by the rules (there
    // is no owner left to check), so check My Trips instead.
    final left = await repository.watchMyTickets().firstWhere(
      (tickets) => tickets.isEmpty,
    );
    expect(left, isEmpty);
  });
}

Map<String, dynamic> _trip(DateTime departure, {required int baseFare}) => {
  'operatorName': 'Trinity Express',
  'fromCode': 'KGL',
  'fromStation': 'Nyabugogo',
  'toCode': 'KLA',
  'toStation': 'Namirembe',
  'departure': departure,
  'arrival': departure.add(const Duration(hours: 9, minutes: 30)),
  'baseFare': baseFare,
  'serviceFee': 500,
  'currency': 'RWF',
  'status': 'scheduled',
};

Map<String, dynamic> _seat(String status, [String? uid, String? bookingId]) => {
  'status': status,
  'heldBy': uid,
  'holdExpiresAt': null,
  'bookingId': bookingId,
};

final HttpClient _http = HttpClient();

/// Writes as the emulator's admin ("Bearer owner"), which skips the rules,
/// the way trips and paid bookings are created outside this feature.
Future<void> _seed(String path, Map<String, dynamic> data) async {
  final request = await _http.patchUrl(
    Uri.parse(
      'http://$_host:$_firestorePort/v1/projects/$_project/databases/'
      '(default)/documents/$path',
    ),
  );
  request.headers
    ..contentType = ContentType.json
    ..set(HttpHeaders.authorizationHeader, 'Bearer owner');
  request.write(
    jsonEncode({
      'fields': data.map((key, value) => MapEntry(key, _value(value))),
    }),
  );
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw StateError('Seeding $path failed: $body');
  }
}

Future<void> _clearFirestore() async {
  final request = await _http.deleteUrl(
    Uri.parse(
      'http://$_host:$_firestorePort/emulator/v1/projects/$_project/'
      'databases/(default)/documents',
    ),
  );
  await (await request.close()).drain<void>();
}

Map<String, dynamic> _value(Object? value) => switch (value) {
  null => {'nullValue': null},
  final String s => {'stringValue': s},
  final int i => {'integerValue': '$i'},
  final bool b => {'booleanValue': b},
  final DateTime d => {'timestampValue': d.toUtc().toIso8601String()},
  _ => throw ArgumentError('Unsupported seed value: $value'),
};
