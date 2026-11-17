import 'package:equatable/equatable.dart';

// A bus company as shown in "Verified operators & safety ratings".
class OperatorRating extends Equatable {
  const OperatorRating({
    required this.id,
    required this.name,
    required this.verified,
    required this.safetyRating,
  });

  final String id;
  final String name;
  final bool verified;

  // Out of 5, from verified passenger feedback.
  final double safetyRating;

  String get ratingLabel => safetyRating.toStringAsFixed(1);

  @override
  List<Object?> get props => [id, name, verified, safetyRating];
}
