/// Which travel documents the traveller has ticked for each booking.
abstract class JourneyChecklistRepository {
  /// Ids of the ticked items for [bookingId]; empty when none are ticked.
  Set<String> checkedItems(String bookingId);

  /// Ticks or unticks [itemId] for [bookingId].
  Future<void> setChecked(
    String bookingId,
    String itemId, {
    required bool checked,
  });
}
