import 'package:flutter_test/flutter_test.dart';

import 'package:bookme_summative_project/features/booking/domain/utils/booking_reference.dart';
import 'package:bookme_summative_project/features/booking/domain/validators/passenger_validators.dart';

void main() {
  group('PassengerValidators', () {
    test('fullName needs first and last name', () {
      expect(PassengerValidators.fullName('Moses Mugisha'), isNull);
      expect(PassengerValidators.fullName("Aïsha O'Neil-Kato"), isNull);
      expect(PassengerValidators.fullName(''), isNotNull);
      expect(PassengerValidators.fullName('Moses'), isNotNull);
      expect(PassengerValidators.fullName('Moses 123'), isNotNull);
    });

    test('phone accepts East African numbers with spaces', () {
      expect(PassengerValidators.phone('+250 78 123 4412'), isNull);
      expect(PassengerValidators.phone('+256-772-123-456'), isNull);
      expect(PassengerValidators.phone('+25779123456'), isNull); // Burundi
      expect(PassengerValidators.phone('0781234412'), isNotNull);
      expect(PassengerValidators.phone('+1 555 123 4567'), isNotNull);
      expect(PassengerValidators.phone(null), isNotNull);
    });

    test('normalizePhone strips formatting', () {
      expect(
        PassengerValidators.normalizePhone('+250 (78) 123-4412'),
        '+250781234412',
      );
    });

    test('email is optional but must look right', () {
      expect(PassengerValidators.optionalEmail(''), isNull);
      expect(PassengerValidators.optionalEmail('a.b+c@mail.co.rw'), isNull);
      expect(PassengerValidators.optionalEmail('not-an-email'), isNotNull);
    });

    test('idNumber is 6-20 letters or digits', () {
      expect(PassengerValidators.idNumber('1199 8800 4412 0036'), isNull);
      expect(PassengerValidators.idNumber('PC12345'), isNull);
      expect(PassengerValidators.idNumber('123'), isNotNull);
      expect(PassengerValidators.idNumber('AB-12345'), isNotNull);
    });

    test('nationality is required', () {
      expect(PassengerValidators.nationality('Rwanda'), isNull);
      expect(PassengerValidators.nationality(null), isNotNull);
    });
  });

  test('booking reference ends with the seat and avoids look-alikes', () {
    final reference = generateBookingReference('4c');
    expect(reference, matches(RegExp(r'^BME-[A-HJ-NP-Z2-9]{4}-4C$')));
  });
}
