import 'package:bookme_summative_project/features/account/domain/account_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('name', () {
    test('accepts a normal full name', () {
      expect(AccountValidators.name('Moses Mugisha'), isNull);
    });

    test('rejects empty, too short and names with digits', () {
      expect(AccountValidators.name(''), isNotNull);
      expect(AccountValidators.name('Al'), isNotNull);
      expect(AccountValidators.name('Moses 2'), isNotNull);
    });
  });

  group('phone', () {
    test('accepts East African numbers, with or without spaces', () {
      expect(AccountValidators.phone('+250 78 123 4412'), isNull);
      expect(AccountValidators.phone('+256772123456'), isNull);
      expect(AccountValidators.phone('+254712345678'), isNull);
    });

    test('rejects local format and other countries', () {
      expect(AccountValidators.phone('0781234412'), isNotNull);
      expect(AccountValidators.phone('+15551234567'), isNotNull);
      expect(AccountValidators.phone(''), isNotNull);
    });
  });

  group('idNumber', () {
    test('accepts passport and national ID formats', () {
      expect(AccountValidators.idNumber('PC1234567'), isNull);
      expect(AccountValidators.idNumber('1199 8800 4412 0036'), isNull);
    });

    test('rejects short or symbol-filled values', () {
      expect(AccountValidators.idNumber('123'), isNotNull);
      expect(AccountValidators.idNumber('AB-12345'), isNotNull);
    });
  });

  test('email is optional but must look like an email when given', () {
    expect(AccountValidators.email(''), isNull);
    expect(AccountValidators.email('moses@example.com'), isNull);
    expect(AccountValidators.email('moses@'), isNotNull);
  });
}
