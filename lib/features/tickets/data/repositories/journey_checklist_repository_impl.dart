import 'package:shared_preferences/shared_preferences.dart';

import 'package:bookme_summative_project/features/tickets/domain/repositories/journey_checklist_repository.dart';

/// Keeps the ticks on the phone only. They are the traveller's own notes,
/// so they never need to reach Firestore and work with no connection.
class JourneyChecklistRepositoryImpl implements JourneyChecklistRepository {
  JourneyChecklistRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static String key(String bookingId) => 'tickets.checklist.$bookingId';

  @override
  Set<String> checkedItems(String bookingId) =>
      (_prefs.getStringList(key(bookingId)) ?? const []).toSet();

  @override
  Future<void> setChecked(
    String bookingId,
    String itemId, {
    required bool checked,
  }) async {
    final items = checkedItems(bookingId);
    if (checked) {
      items.add(itemId);
    } else {
      items.remove(itemId);
    }
    await _prefs.setStringList(key(bookingId), items.toList()..sort());
  }
}
