import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/tickets/data/models/ticket_cache_model.dart';
import 'package:bookme_summative_project/features/tickets/domain/entities/ticket.dart';

/// Keeps a copy of the traveller's tickets on the device, so the ticket and
/// its QR code still open at a border post with no signal.
///
/// Each account gets its own key, so signing in with a different account on
/// the same phone never shows someone else's tickets.
class TicketCacheDataSource {
  TicketCacheDataSource(this._prefs);

  final SharedPreferences _prefs;

  /// Enough for every realistic upcoming trip plus recent history, while
  /// keeping the stored JSON small.
  static const int maxTickets = 20;

  static String ticketsKey(String userId) => 'tickets.cache.$userId';
  static String syncedAtKey(String userId) => 'tickets.syncedAt.$userId';

  /// Replaces the cached tickets for [userId] with [tickets].
  Future<void> save(String userId, List<Ticket> tickets) async {
    final encoded = jsonEncode([
      for (final ticket in tickets.take(maxTickets))
        TicketCacheModel.toJson(ticket),
    ]);
    await _prefs.setString(ticketsKey(userId), encoded);
    await _prefs.setString(
      syncedAtKey(userId),
      DateTime.now().toIso8601String(),
    );
  }

  /// Cached tickets for [userId], or an empty list when nothing is stored
  /// or the stored data can no longer be read.
  List<Ticket> load(String userId) {
    final raw = _prefs.getString(ticketsKey(userId));
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          TicketCacheModel.fromJson(Map<String, dynamic>.from(item as Map)),
      ];
    } on Object {
      return const [];
    }
  }

  /// When the cache was last refreshed from Firestore.
  DateTime? lastSyncedAt(String userId) {
    final raw = _prefs.getString(syncedAtKey(userId));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Removes the cached tickets, e.g. when the traveller signs out.
  Future<void> clear(String userId) async {
    await _prefs.remove(ticketsKey(userId));
    await _prefs.remove(syncedAtKey(userId));
  }
}
