// Form checks for the profile and passenger forms. Each returns an error
// message, or null when the value is fine (what TextFormField expects).
class AccountValidators {
  const AccountValidators._();

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter the full name';
    if (v.length < 3) return 'Name looks too short';
    if (RegExp(r'\d').hasMatch(v)) return 'Names can\'t contain numbers';
    return null;
  }

  // East African mobile numbers in international form, e.g. +250781234412.
  static String? phone(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (v.isEmpty) return 'Enter a phone number';
    if (!RegExp(r'^\+(250|256|254|255|211|257)\d{9}$').hasMatch(v)) {
      return 'Use the format +250 78 123 4412';
    }
    return null;
  }

  static String? idNumber(String? value) {
    final v = (value ?? '').replaceAll(' ', '');
    if (v.isEmpty) return 'Enter the passport or ID number';
    if (v.length < 6) return 'That number looks too short';
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(v)) {
      return 'Use letters and numbers only';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // optional
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'That email address doesn\'t look right';
    }
    return null;
  }

  static String? required(String? value, String label) =>
      (value?.trim() ?? '').isEmpty ? 'Enter $label' : null;

  // Stored without spaces so numbers compare equal.
  static String normalisePhone(String value) =>
      value.replaceAll(RegExp(r'[\s-]'), '');
}
