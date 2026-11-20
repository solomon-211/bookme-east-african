/// Small display helpers shared by every feature.
///
/// Written by hand (instead of pulling in `intl`) because we only need
/// three formats and they must look the same on every phone locale.
class Formatters {
  const Formatters._();

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// `18500, 'RWF'` → `18,500 RWF`.
  static String money(int amount, String currency) {
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
    }
    final sign = amount < 0 ? '-' : '';
    return '$sign$buffer $currency';
  }

  /// 24-hour clock, e.g. `21:00`.
  static String time(DateTime value) =>
      '${_two(value.hour)}:${_two(value.minute)}';

  /// e.g. `Fri 2 Oct`.
  static String shortDate(DateTime value) =>
      '${_weekdays[value.weekday - 1]} ${value.day} ${_months[value.month - 1]}';

  /// Countdown, e.g. `09:59`.
  static String countdown(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    final minutes = safe.inMinutes;
    final seconds = safe.inSeconds % 60;
    return '${_two(minutes)}:${_two(seconds)}';
  }

  /// `+250781234412` → `+250 78 123 4412` (falls back to the raw value).
  static String phone(String e164) {
    final match = RegExp(r'^\+(\d{3})(\d{2})(\d{3})(\d+)$').firstMatch(e164);
    if (match == null) return e164;
    return '+${match[1]} ${match[2]} ${match[3]} ${match[4]}';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
