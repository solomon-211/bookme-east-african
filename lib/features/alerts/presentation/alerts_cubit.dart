import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/alerts_repository.dart';
import '../domain/app_alert.dart';
import 'alerts_state.dart';

class AlertsCubit extends Cubit<AlertsState> {
  AlertsCubit(this._repository) : super(const AlertsState());

  final AlertsRepository _repository;
  StreamSubscription<List<AppAlert>>? _sub;

  void start() {
    _sub?.cancel();
    _sub = _repository.watchAlerts().listen(
      (alerts) =>
          emit(state.copyWith(status: AlertsStatus.ready, alerts: alerts)),
      onError: (_) => emit(
        state.copyWith(
          status: AlertsStatus.failure,
          errorMessage: 'We couldn\'t load your alerts.',
        ),
      ),
    );
  }

  void setFilter(AlertFilter filter) => emit(state.copyWith(filter: filter));

  Future<void> markRead(AppAlert alert) async {
    if (alert.read) return;
    await _guard(() => _repository.markRead(alert.id));
  }

  Future<void> delete(AppAlert alert) async {
    // Hide it straight away so the swipe feels instant.
    emit(
      state.copyWith(
        alerts: state.alerts.where((a) => a.id != alert.id).toList(),
      ),
    );
    await _guard(() => _repository.deleteAlert(alert.id));
  }

  // "Undo" on the snackbar after a delete.
  Future<void> restore(AppAlert alert) =>
      _guard(() => _repository.addAlert(alert));

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'That didn\'t save. Check your connection.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
