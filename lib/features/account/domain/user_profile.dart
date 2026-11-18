import 'package:equatable/equatable.dart';

import '../../../core/utils/formatters.dart';

class IdDocument extends Equatable {
  const IdDocument({
    required this.type,
    required this.country,
    required this.number,
  });

  static const types = ['EAC ID', 'Passport', 'National ID'];

  final String type;
  final String country;
  final String number;

  // "EAC ID · Rwanda · Ending 0036". Only the last 4 digits are ever shown.
  String get summary {
    final digits = number.replaceAll(RegExp(r'\s'), '');
    final last4 = digits.length <= 4
        ? digits
        : digits.substring(digits.length - 4);
    return '$type · $country · Ending $last4';
  }

  @override
  List<Object?> get props => [type, country, number];
}

class MobileMoneyAccount extends Equatable {
  const MobileMoneyAccount({required this.provider, required this.phone});

  static const providers = ['MTN MoMo', 'Airtel Money', 'M-Pesa'];

  final String provider;
  final String phone;

  String get summary => '$provider · ${Formatters.phone(phone)}';

  @override
  List<Object?> get props => [provider, phone];
}

// The signed-in traveller, stored in users/{uid}.
class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.phone,
    this.email,
    this.phoneVerified = false,
    this.idDocument,
    this.mobileMoney,
  });

  final String uid;
  final String fullName;
  final String phone;
  final String? email;
  final bool phoneVerified;
  final IdDocument? idDocument;
  final MobileMoneyAccount? mobileMoney;

  // "Moses Mugisha" -> "MM" for the avatar.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get displayName => fullName.trim().isEmpty ? 'Traveller' : fullName;

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? email,
    bool? phoneVerified,
    IdDocument? idDocument,
    MobileMoneyAccount? mobileMoney,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      idDocument: idDocument ?? this.idDocument,
      mobileMoney: mobileMoney ?? this.mobileMoney,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    fullName,
    phone,
    email,
    phoneVerified,
    idDocument,
    mobileMoney,
  ];
}
