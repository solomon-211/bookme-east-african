import 'operator_rating.dart';

abstract class TrustRepository {
  // Verified operators only, in the order they should be listed.
  Future<List<OperatorRating>> fetchVerifiedOperators();
}
