import 'package:equatable/equatable.dart';

import '../domain/saved_passenger.dart';
import '../domain/user_profile.dart';

enum AccountStatus { loading, ready, signedOut, failure }

class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.loading,
    this.profile,
    this.passengers = const [],
    this.saving = false,
    this.message,
    this.messageId = 0,
  });

  final AccountStatus status;
  final UserProfile? profile;
  final List<SavedPassenger> passengers;

  // True while a save is in flight, to disable the Save buttons.
  final bool saving;

  // One-off snackbar text. messageId changes each time, so the same
  // text twice in a row is still shown twice.
  final String? message;
  final int messageId;

  // "Moses Mugisha · 1 passenger"
  String get passengersSummary {
    if (passengers.isEmpty) return 'Add the people you travel with';
    final count = passengers.length;
    final noun = count == 1 ? 'passenger' : 'passengers';
    return '${passengers.first.fullName} · $count $noun';
  }

  AccountState copyWith({
    AccountStatus? status,
    UserProfile? profile,
    List<SavedPassenger>? passengers,
    bool? saving,
  }) {
    return AccountState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      passengers: passengers ?? this.passengers,
      saving: saving ?? this.saving,
      message: message,
      messageId: messageId,
    );
  }

  AccountState withMessage(String text) => AccountState(
    status: status,
    profile: profile,
    passengers: passengers,
    saving: false,
    message: text,
    messageId: messageId + 1,
  );

  @override
  List<Object?> get props => [
    status,
    profile,
    passengers,
    saving,
    message,
    messageId,
  ];
}
