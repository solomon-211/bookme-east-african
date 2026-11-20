import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/escrow_record.dart';
import '../domain/escrow_repository.dart';

enum EscrowViewStatus { loading, ready, notFound, failure }

class EscrowState extends Equatable {
  const EscrowState({this.status = EscrowViewStatus.loading, this.record});

  final EscrowViewStatus status;
  final EscrowRecord? record;

  @override
  List<Object?> get props => [status, record];
}

// Follows one booking's escrow live, so the screen moves on by itself
// when boarding is verified or a refund is issued.
class EscrowCubit extends Cubit<EscrowState> {
  EscrowCubit(this._repository) : super(const EscrowState());

  final EscrowRepository _repository;
  StreamSubscription<EscrowRecord?>? _sub;

  void watch(String bookingId) {
    _sub?.cancel();
    emit(const EscrowState());
    _sub = _repository
        .watchEscrow(bookingId)
        .listen(
          (record) => emit(
            record == null
                ? const EscrowState(status: EscrowViewStatus.notFound)
                : EscrowState(status: EscrowViewStatus.ready, record: record),
          ),
          onError: (_) =>
              emit(const EscrowState(status: EscrowViewStatus.failure)),
        );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
