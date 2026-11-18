import 'package:equatable/equatable.dart';

// Someone the user often books for. Same fields as the booking form's
// passenger, so "Who's travelling?" can be filled from this list.
class SavedPassenger extends Equatable {
  const SavedPassenger({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.idNumber,
    required this.nationality,
  });

  final String id; // empty until saved
  final String fullName;
  final String phone;
  final String idNumber;
  final String nationality;

  SavedPassenger copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? idNumber,
    String? nationality,
  }) {
    return SavedPassenger(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      idNumber: idNumber ?? this.idNumber,
      nationality: nationality ?? this.nationality,
    );
  }

  @override
  List<Object?> get props => [id, fullName, phone, idNumber, nationality];
}
