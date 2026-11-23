import 'package:bookme_summative_project/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('accepts a normal address, ignoring spaces around it', () {
      expect(Validators.email(' moses@example.com '), isNull);
    });

    test('rejects empty and malformed addresses', () {
      expect(Validators.email(''), Validators.emailRequired);
      expect(Validators.email('moses@'), Validators.emailInvalid);
      expect(Validators.email('moses.example.com'), Validators.emailInvalid);
    });
  });

  group('passwords', () {
    test('login only checks that something was typed', () {
      expect(Validators.passwordRequiredOnly(''), Validators.passwordRequired);
      expect(Validators.passwordRequiredOnly('abc'), isNull);
    });

    test('registration needs 8+ characters with a letter and a number', () {
      expect(Validators.newPassword('a1'), Validators.passwordTooShort);
      expect(Validators.newPassword('abcdefgh'), Validators.passwordWeak);
      expect(Validators.newPassword('12345678'), Validators.passwordWeak);
      expect(Validators.newPassword('kigali2026'), isNull);
    });

    test('confirm password must match the first one', () {
      final confirm = Validators.confirmPassword(() => 'kigali2026');
      expect(confirm(''), Validators.confirmRequired);
      expect(confirm('kigali2025'), Validators.confirmMismatch);
      expect(confirm('kigali2026'), isNull);
    });
  });

  group('phone', () {
    test('local numbers lose spaces, dashes and one leading zero', () {
      expect(Validators.normalizeLocalPhone('0788 123-456'), '788123456');
    });

    test('builds an E.164 number from the chosen country code', () {
      expect(Validators.toE164('+250', '0788 123 456'), '+250788123456');
    });

    test('local part must be 8 to 10 digits', () {
      expect(Validators.localPhone(''), Validators.phoneRequired);
      expect(Validators.localPhone('1234'), Validators.phoneInvalid);
      expect(Validators.localPhone('78 123 4412'), isNull);
    });
  });

  test('OTP must be exactly six digits', () {
    expect(Validators.otp(''), Validators.otpRequired);
    expect(Validators.otp('12345'), Validators.otpInvalid);
    expect(Validators.otp('12a456'), Validators.otpInvalid);
    expect(Validators.otp('482017'), isNull);
  });

  test('full name needs at least two characters', () {
    expect(Validators.fullName(' '), Validators.nameRequired);
    expect(Validators.fullName('M'), Validators.nameTooShort);
    expect(Validators.fullName('Moses Mugisha'), isNull);
  });
}
