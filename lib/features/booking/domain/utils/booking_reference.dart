import 'dart:math';

/// Letters and digits that cannot be confused when read aloud or typed at a
/// counter (no 0/O, 1/I).
const String _referenceAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// Builds a booking reference such as `BME-7K2Q-4C`.
///
/// The last part is the seat number so staff can read the seat straight
/// off the code. Pass a seeded [random] in tests for a predictable result.
String generateBookingReference(String seatNumber, {Random? random}) {
  final rng = random ?? Random.secure();
  final code = List.generate(
    4,
    (_) => _referenceAlphabet[rng.nextInt(_referenceAlphabet.length)],
  ).join();
  return 'BME-$code-${seatNumber.toUpperCase()}';
}

/// Public link the payer opens when someone else is paying.
String buildPaymentLink(String reference) =>
    'https://bookme.app/pay/$reference';
