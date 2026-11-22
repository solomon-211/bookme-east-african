import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/search/domain/entities/city.dart';

/// A route the traveller searched before, shown under "Book again".
class RecentRoute extends Equatable {
  const RecentRoute(this.origin, this.destination);

  final City origin;
  final City destination;

  @override
  List<Object?> get props => [origin, destination];
}

/// Remembers the last few searched routes on the phone.
///
/// Kept in SharedPreferences, not Firestore: it's a convenience for this
/// device only and needs no network.
class RecentRoutesStore {
  RecentRoutesStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'search.recentRoutes';
  static const maxRoutes = 3;

  List<RecentRoute> load() {
    final raw = _prefs.getStringList(_key) ?? const [];
    final routes = <RecentRoute>[];
    for (final item in raw) {
      final parts = item.split('|');
      if (parts.length != 2) continue;
      final from = Cities.byName(parts[0]);
      final to = Cities.byName(parts[1]);
      if (from != null && to != null && from != to) {
        routes.add(RecentRoute(from, to));
      }
    }
    return routes;
  }

  /// Puts [route] first, removes duplicates and keeps [maxRoutes].
  Future<List<RecentRoute>> remember(RecentRoute route) async {
    final routes = [
      route,
      ...load().where((r) => r != route),
    ].take(maxRoutes).toList();
    await _prefs.setStringList(_key, [
      for (final r in routes) '${r.origin.name}|${r.destination.name}',
    ]);
    return routes;
  }
}
