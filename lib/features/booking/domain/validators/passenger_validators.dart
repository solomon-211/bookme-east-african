/// Pure validation functions used by the booking forms.
///
/// Each returns `null` when the value is valid, or a polite message to show
/// under the field. Keeping them free of Flutter makes them easy to unit test.
class PassengerValidators {
  const PassengerValidators._();

  /// Country codes we sell tickets in: Rwanda, Uganda, Kenya, Tanzania,
  /// South Sudan (9 local digits) and Burundi (8 local digits).
  static final RegExp _phonePattern = RegExp(
    r'^\+(?:(?:250|256|254|255|211)\d{9}|257\d{8})$',
  );

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$',
  );

  static final RegExp _namePattern = RegExp(r"^[A-Za-zÀ-ÿ' -]+$");

  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9]{6,20}$');

  /// Removes spaces, dashes and brackets: `+250 78 123 4412` → `+250781234412`.
  static String normalizePhone(String raw) =>
      raw.replaceAll(RegExp(r'[\s\-()]'), '');

  static String? fullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Please enter the passenger\'s full name.';
    if (!_namePattern.hasMatch(name)) {
      return 'Names can only contain letters, spaces, hyphens and apostrophes.';
    }
    if (name.split(RegExp(r'\s+')).length < 2) {
      return 'Enter first and last name exactly as on the ID document.';
    }
    return null;
  }

  static String? phone(String? value) {
    final phone = normalizePhone(value ?? '');
    if (phone.isEmpty) return 'Please enter a phone number.';
    if (!_phonePattern.hasMatch(phone)) {
      return 'Use the full number with country code, e.g. +250 78 123 4412.';
    }
    return null;
  }

  /// Email is optional (it only receives a copy of the receipt).
  static String? optionalEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!_emailPattern.hasMatch(email)) {
      return 'That email address doesn\'t look right.';
    }
    return null;
  }

  static String? idNumber(String? value) {
    final id = (value ?? '').replaceAll(' ', '');
    if (id.isEmpty) {
      return 'A passport or EAC ID number is needed at the border.';
    }
    if (!_idPattern.hasMatch(id)) {
      return 'ID numbers are 6–20 letters or digits, no symbols.';
    }
    return null;
  }

  static String? nationality(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please choose a nationality.';
    }
    return null;
  }
}
