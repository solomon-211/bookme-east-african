import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore: operators/{operatorId}
class BusOperator extends Equatable {
  const BusOperator({
    required this.id,
    required this.name,
    required this.contactPhone,
    this.rating = 0,
    this.isVerified = false,
    this.refundPolicy = '',
  });

  final String id;
  final String name;
  final String contactPhone;
  final double rating;
  final bool isVerified;
  final String refundPolicy;

  factory BusOperator.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BusOperator(
      id: doc.id,
      name: d['name'] as String,
      contactPhone: (d['contactPhone'] ?? '') as String,
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      isVerified: d['isVerified'] as bool? ?? false,
      refundPolicy: (d['refundPolicy'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'contactPhone': contactPhone,
    'rating': rating,
    'isVerified': isVerified,
    'refundPolicy': refundPolicy,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    contactPhone,
    rating,
    isVerified,
    refundPolicy,
  ];
}
