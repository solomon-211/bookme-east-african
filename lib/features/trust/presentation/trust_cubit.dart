import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/operator_rating.dart';
import '../domain/trust_repository.dart';

enum TrustStatus { loading, ready, failure }

class TrustState extends Equatable {
  const TrustState({
    this.status = TrustStatus.loading,
    this.operators = const [],
  });

  final TrustStatus status;
  final List<OperatorRating> operators;

  @override
  List<Object?> get props => [status, operators];
}

class TrustCubit extends Cubit<TrustState> {
  TrustCubit(this._repository) : super(const TrustState());

  final TrustRepository _repository;

  Future<void> load() async {
    emit(const TrustState());
    try {
      final operators = await _repository.fetchVerifiedOperators();
      emit(TrustState(status: TrustStatus.ready, operators: operators));
    } catch (_) {
      emit(const TrustState(status: TrustStatus.failure));
    }
  }
}
