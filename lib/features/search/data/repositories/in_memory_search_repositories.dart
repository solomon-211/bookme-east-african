import 'dart:async';

import 'package:bookme_summative_project/data/models/bus_operator.dart';
import 'package:bookme_summative_project/features/search/data/models/bus_trip_model.dart';
import 'package:bookme_summative_project/features/search/data/seed/search_seed_data.dart';
import 'package:bookme_summative_project/features/search/domain/entities/bus_trip.dart';
import 'package:bookme_summative_project/features/search/domain/entities/waitlist_entry.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/search_repository.dart';
import 'package:bookme_summative_project/features/search/domain/repositories/waitlist_repository.dart';

/// [SearchRepository] over a fixed list, for tests and the offline demo.
class InMemorySearchRepository implements SearchRepository {
  InMemorySearchRepository({
    required this._trips,
    required this._operators,
    this.latency = Duration.zero,
  });

  /// The seed data, with trips for [days] days from [start].
  factory InMemorySearchRepository.seeded(
    DateTime start, {
    int days = 10,
    Duration latency = Duration.zero,
  }) => InMemorySearchRepository(
    trips: seedTrips(start, days: days),
    operators: seedOperatorModels(),
    latency: latency,
  );

  final List<BusTrip> _trips;
  final List<BusOperator> _operators;
  final Duration latency;

  /// When set, every call throws it. Lets tests check error states.
  SearchFailure? failure;

  /// How many times [searchTrips] ran, so tests can check caching.
  int searchCalls = 0;

  @override
  Future<List<BusTrip>> searchTrips({
    required String origin,
    required String destination,
    required DateTime from,
    required DateTime to,
  }) async {
    searchCalls++;
    await _wait();
    return _trips
        .where(
          (t) =>
              t.origin == origin &&
              t.destination == destination &&
              !t.departure.isBefore(from) &&
              t.departure.isBefore(to),
        )
        .toList()
      ..sort((a, b) => a.departure.compareTo(b.departure));
  }

  @override
  Future<BusTrip?> tripById(String tripId) async {
    await _wait();
    for (final trip in _trips) {
      if (trip.id == tripId) return trip;
    }
    return null;
  }

  @override
  Future<List<BusOperator>> operators() async {
    await _wait();
    return [..._operators]..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final error = failure;
    if (error != null) throw error;
  }

  static List<BusTrip> seedTrips(DateTime start, {int days = 10}) => [
    for (final map in generateSeedTrips(start, days: days))
      ?BusTripModel.fromMap(map['id']! as String, map),
  ];

  static List<BusOperator> seedOperatorModels() => [
    for (final o in seedOperators)
      BusOperator(
        id: o['id']! as String,
        name: o['name']! as String,
        contactPhone: o['contactPhone']! as String,
        rating: o['rating']! as double,
        isVerified: o['isVerified']! as bool,
        refundPolicy: o['refundPolicy']! as String,
      ),
  ];
}

/// [WaitlistRepository] kept in memory, for tests and the offline demo.
class InMemoryWaitlistRepository implements WaitlistRepository {
  InMemoryWaitlistRepository({this.userId = 'demo-user', DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final String userId;
  final DateTime Function() _now;
  final Map<String, WaitlistEntry> _entries = {};
  final StreamController<List<WaitlistEntry>> _changes =
      StreamController<List<WaitlistEntry>>.broadcast();

  /// When set, [join] and [leave] throw it.
  SearchFailure? failure;

  List<WaitlistEntry> get entries => _sorted();

  @override
  Stream<List<WaitlistEntry>> watchMine() async* {
    yield _sorted();
    yield* _changes.stream;
  }

  @override
  Future<WaitlistEntry> join({
    required BusTrip trip,
    required String phone,
  }) async {
    final error = failure;
    if (error != null) throw error;
    final entry = WaitlistEntry(
      id: WaitlistEntry.idFor(userId, trip.id),
      userId: userId,
      tripId: trip.id,
      phone: phone,
      origin: trip.origin,
      destination: trip.destination,
      operatorName: trip.operatorName,
      departure: trip.departure,
      createdAt: _now(),
    );
    _entries[entry.id] = entry;
    _changes.add(_sorted());
    return entry;
  }

  @override
  Future<void> leave(String entryId) async {
    final error = failure;
    if (error != null) throw error;
    _entries.remove(entryId);
    _changes.add(_sorted());
  }

  List<WaitlistEntry> _sorted() => _entries.values.toList()
    ..sort((a, b) => (b.createdAt ?? _now()).compareTo(a.createdAt ?? _now()));

  Future<void> dispose() => _changes.close();
}
