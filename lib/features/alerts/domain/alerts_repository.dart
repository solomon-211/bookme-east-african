import 'app_alert.dart';

abstract class AlertsRepository {
  // Newest first. Emits again whenever an alert is added, read or deleted.
  Stream<List<AppAlert>> watchAlerts();

  // Other features call this, e.g. Search when a waitlisted seat opens.
  Future<void> addAlert(AppAlert alert);

  Future<void> markRead(String alertId);

  Future<void> deleteAlert(String alertId);
}
