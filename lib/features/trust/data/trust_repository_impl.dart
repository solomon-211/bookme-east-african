import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/operator_rating.dart';
import '../domain/trust_repository.dart';

// Reads the `operators` collection that the Search feature seeds.
class TrustRepositoryImpl implements TrustRepository {
  TrustRepositoryImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Future<List<OperatorRating>> fetchVerifiedOperators() async {
    final snapshot = await _db.collection('operators').get();

    final operators = snapshot.docs
        .map((doc) => operatorFromMap(doc.id, doc.data()))
        .where((op) => op.verified)
        .toList();

    // Highest rated first.
    operators.sort((a, b) => b.safetyRating.compareTo(a.safetyRating));
    return operators;
  }

  // Search owns this collection, so accept both field spellings we have
  // seen in the team's seed data rather than failing on one of them.
  static OperatorRating operatorFromMap(String id, Map<String, dynamic> map) {
    final rating = map['safetyRating'] ?? map['rating'] ?? 0;
    return OperatorRating(
      id: id,
      name: (map['name'] as String?) ?? id,
      verified: (map['verified'] ?? map['isVerified'] ?? false) as bool,
      safetyRating: (rating as num).toDouble(),
    );
  }
}

class InMemoryTrustRepository implements TrustRepository {
  InMemoryTrustRepository([List<OperatorRating>? operators])
    : _operators = operators ?? demoOperators;

  final List<OperatorRating> _operators;

  static const demoOperators = [
    OperatorRating(
      id: 'trinity',
      name: 'Trinity Express',
      verified: true,
      safetyRating: 4.6,
    ),
    OperatorRating(
      id: 'jaguar',
      name: 'Jaguar',
      verified: true,
      safetyRating: 4.3,
    ),
    OperatorRating(
      id: 'ritco',
      name: 'RITCO',
      verified: true,
      safetyRating: 4.4,
    ),
    OperatorRating(
      id: 'volcano',
      name: 'Volcano Express',
      verified: true,
      safetyRating: 4.1,
    ),
  ];

  @override
  Future<List<OperatorRating>> fetchVerifiedOperators() async =>
      _operators.where((op) => op.verified).toList();
}
