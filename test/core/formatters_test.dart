import 'package:flutter_test/flutter_test.dart';

import 'package:bookme_summative_project/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    test('money adds thousands separators and the currency', () {
      expect(Formatters.money(0, 'RWF'), '0 RWF');
      expect(Formatters.money(500, 'RWF'), '500 RWF');
      expect(Formatters.money(18500, 'RWF'), '18,500 RWF');
      expect(Formatters.money(1234567, 'UGX'), '1,234,567 UGX');
      expect(Formatters.money(-2500, 'RWF'), '-2,500 RWF');
    });

    test('time and shortDate', () {
      final value = DateTime(2026, 12, 4, 21, 5);
      expect(Formatters.time(value), '21:05');
      expect(Formatters.shortDate(value), 'Fri 4 Dec');
    });

    test('countdown never goes negative', () {
      expect(
        Formatters.countdown(const Duration(minutes: 9, seconds: 59)),
        '09:59',
      );
      expect(Formatters.countdown(const Duration(seconds: -5)), '00:00');
    });

    test('phone groups E.164 numbers and keeps anything else as is', () {
      expect(Formatters.phone('+250781234412'), '+250 78 123 4412');
      expect(Formatters.phone('0781234412'), '0781234412');
    });
  });
}
