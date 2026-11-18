import 'package:equatable/equatable.dart';

import '../domain/app_alert.dart';

enum AlertsStatus { loading, ready, failure }

class AlertsState extends Equatable {
  const AlertsState({
    this.status = AlertsStatus.loading,
    this.alerts = const [],
    this.filter = AlertFilter.all,
    this.errorMessage,
  });

  final AlertsStatus status;
  final List<AppAlert> alerts;
  final AlertFilter filter;
  final String? errorMessage;

  List<AppAlert> get visibleAlerts =>
      alerts.where((a) => a.matches(filter)).toList();

  int get unreadCount => alerts.where((a) => !a.read).length;

  AlertsState copyWith({
    AlertsStatus? status,
    List<AppAlert>? alerts,
    AlertFilter? filter,
    String? errorMessage,
  }) {
    return AlertsState(
      status: status ?? this.status,
      alerts: alerts ?? this.alerts,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, alerts, filter, errorMessage];
}
