// Writes the Search seed data (operators, routes, trips, seats) to JSON so
// `tool/seed/seed_search.js` can upload it with the Firebase Admin SDK.
//
//   dart run tool/export_search_seed.dart            # 10 days from today
//   dart run tool/export_search_seed.dart --days 14
//
// Pure Dart: it only imports the seed file, which has no Flutter imports.

import 'dart:convert';
import 'dart:io';

import 'package:bookme_summative_project/features/search/data/seed/search_seed_data.dart';

void main(List<String> args) {
  var days = 10;
  final i = args.indexOf('--days');
  if (i != -1 && i + 1 < args.length) days = int.parse(args[i + 1]);

  final trips = generateSeedTrips(DateTime.now(), days: days);
  final data = {
    'operators': seedOperators,
    'routes': [for (final r in seedRoutes) r.toMap()],
    'trips': [
      for (final t in trips)
        {...t, 'seatNumbers': seedSeatNumbers(t['seatsTotal']! as int)},
    ],
  };

  final out = File('tool/seed/search_seed.json')..createSync(recursive: true);
  out.writeAsStringSync(
    const JsonEncoder.withIndent('  ', _toJson).convert(data),
  );
  stdout.writeln(
    'Wrote ${seedOperators.length} operators, ${seedRoutes.length} routes, '
    '${trips.length} trips to ${out.path}',
  );
}

/// DateTimes become ISO-8601 strings (the upload script turns them back
/// into Firestore timestamps).
Object? _toJson(Object? value) =>
    value is DateTime ? value.toUtc().toIso8601String() : value;
