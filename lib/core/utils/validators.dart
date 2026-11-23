/// Pure form validators. Each returns an error message, or null when valid.
class Validators {
  Validators._();

  static const emailRequired = 'Enter your email';
  static const emailInvalid = 'Enter a valid email address';
  static const passwordRequired = 'Enter your password';
  static const passwordTooShort = 'Use at least 8 characters';
  static const passwordWeak = 'Include at least one letter and one number';
  static const confirmRequired = 'Confirm your password';
  static const confirmMismatch = 'Passwords do not match';
  static const nameRequired = 'Enter your full name';
  static const nameTooShort = 'Name must be at least 2 characters';
  static const phoneRequired = 'Enter your phone number';
  static const phoneInvalid = 'Enter a valid phone number';
  static const otpRequired = 'Enter the 6-digit code';
  static const otpInvalid = 'The code must be exactly 6 digits';

  static final _emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return emailRequired;
    if (!_emailRegex.hasMatch(v)) return emailInvalid;
    return null;
  }

  /// Used on login: only checks presence so older passwords still work.
  static String? passwordRequiredOnly(String? value) {
    if (value == null || value.isEmpty) return passwordRequired;
    return null;
  }

  /// Used on registration: minimum strength rules.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return passwordRequired;
    if (value.length < 8) return passwordTooShort;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    if (!hasLetter || !hasDigit) return passwordWeak;
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) return confirmRequired;
      if (value != original()) return confirmMismatch;
      return null;
    };
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return nameRequired;
    if (v.length < 2) return nameTooShort;
    return null;
  }

  /// Strips spaces/dashes/brackets and one leading zero from a local number.
  static String normalizeLocalPhone(String input) {
    var digits = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  /// Validates the local part of a phone number (country code chosen separately).
  static String? localPhone(String? value) {
    final v = normalizeLocalPhone(value ?? '');
    if (v.isEmpty) return phoneRequired;
    if (!RegExp(r'^\d{8,10}$').hasMatch(v)) return phoneInvalid;
    return null;
  }

  /// Builds an E.164 number, e.g. ('+250', '0788 123 456') -> '+250788123456'.
  static String toE164(String dialCode, String local) =>
      '$dialCode${normalizeLocalPhone(local)}';

  static String? otp(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return otpRequired;
    if (!RegExp(r'^\d{6}$').hasMatch(v)) return otpInvalid;
    return null;
  }
}
