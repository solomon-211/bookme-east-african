import 'package:equatable/equatable.dart';

/// The person who will physically board the bus.
///
/// Stored inside the booking document (not in its own collection) because a
/// passenger record only ever belongs to one booking. Saved passengers for
/// re-use live in the Account feature.
class Passenger extends Equatable {
  const Passenger({
    required this.fullName,
    required this.phone,
    required this.idNumber,
    required this.nationality,
    this.email,
  });

  final String fullName;

  /// E.164 format without spaces, e.g. `+250781234412`.
  final String phone;

  /// Passport or EAC ID number. Only shared with the operator for the
  /// border manifest.
  final String idNumber;
  final String nationality;
  final String? email;

  @override
  List<Object?> get props => [fullName, phone, idNumber, nationality, email];
}
