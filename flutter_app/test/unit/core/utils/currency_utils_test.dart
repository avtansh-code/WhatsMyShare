import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/core/utils/currency_utils.dart';

void main() {
  group('CurrencyUtils', () {
    group('format', () {
      test('formats INR correctly', () {
        // 10050 paisa = ₹100.50
        final result = CurrencyUtils.format(10050, 'INR');
        expect(result, contains('100'));
        expect(result, contains('50'));
        expect(result, contains('₹'));
      });

      test('formats USD correctly', () {
        final result = CurrencyUtils.format(10050, 'USD');
        expect(result, contains('100'));
        expect(result, contains('50'));
        expect(result, contains('\$'));
      });

      test('formats EUR correctly', () {
        final result = CurrencyUtils.format(10050, 'EUR');
        expect(result, contains('100'));
        expect(result, contains('€'));
      });

      test('formats GBP correctly', () {
        final result = CurrencyUtils.format(10050, 'GBP');
        expect(result, contains('100'));
        expect(result, contains('£'));
      });

      test('formats zero amount', () {
        final result = CurrencyUtils.format(0, 'INR');
        expect(result, contains('0'));
      });

      test('formats large amounts', () {
        // 1,00,00,000 paisa = ₹1,00,000.00 (Indian numbering)
        final result = CurrencyUtils.format(10000000, 'INR');
        expect(result, contains('1,00,000'));
        expect(result, contains('₹'));
      });

      test('handles unknown currency code', () {
        final result = CurrencyUtils.format(10050, 'XYZ');
        expect(result, contains('100'));
      });
    });

    group('formatWithSign', () {
      test('formats positive amount with plus sign', () {
        final result = CurrencyUtils.formatWithSign(10050, 'INR');
        expect(result, startsWith('+'));
        expect(result, contains('100'));
      });

      test('formats negative amount with minus sign', () {
        final result = CurrencyUtils.formatWithSign(-10050, 'INR');
        expect(result, startsWith('-'));
        expect(result, contains('100'));
      });

      test('formats zero without sign', () {
        final result = CurrencyUtils.formatWithSign(0, 'INR');
        expect(result, isNot(startsWith('+')));
        expect(result, isNot(startsWith('-')));
      });
    });

    group('parse', () {
      test('parses simple amount', () {
        final result = CurrencyUtils.parse('100.50');
        expect(result, 10050);
      });

      test('parses amount with currency symbol', () {
        final result = CurrencyUtils.parse('₹100.50');
        expect(result, 10050);
      });

      test('parses amount with dollar sign', () {
        final result = CurrencyUtils.parse('\$100.50');
        expect(result, 10050);
      });

      test('parses amount with commas', () {
        final result = CurrencyUtils.parse('1,000.50');
        expect(result, 100050);
      });

      test('parses whole number', () {
        final result = CurrencyUtils.parse('100');
        expect(result, 10000);
      });

      test('returns zero for empty string', () {
        final result = CurrencyUtils.parse('');
        expect(result, 0);
      });

      test('returns zero for invalid string', () {
        final result = CurrencyUtils.parse('abc');
        expect(result, 0);
      });

      test('handles only symbols', () {
        final result = CurrencyUtils.parse('₹');
        expect(result, 0);
      });

      test('rounds to nearest paisa', () {
        final result = CurrencyUtils.parse('100.505');
        expect(result, 10051);
      });
    });

    group('getSymbol', () {
      test('returns ₹ for INR', () {
        expect(CurrencyUtils.getSymbol('INR'), '₹');
      });

      test('returns \$ for USD', () {
        expect(CurrencyUtils.getSymbol('USD'), '\$');
      });

      test('returns € for EUR', () {
        expect(CurrencyUtils.getSymbol('EUR'), '€');
      });

      test('returns £ for GBP', () {
        expect(CurrencyUtils.getSymbol('GBP'), '£');
      });

      test('returns ¥ for JPY', () {
        expect(CurrencyUtils.getSymbol('JPY'), '¥');
      });

      test('returns currency code for unknown', () {
        expect(CurrencyUtils.getSymbol('XYZ'), 'XYZ');
      });

      test('is case insensitive', () {
        expect(CurrencyUtils.getSymbol('inr'), '₹');
        expect(CurrencyUtils.getSymbol('Inr'), '₹');
        expect(CurrencyUtils.getSymbol('INR'), '₹');
      });
    });

    group('getName', () {
      test('returns Indian Rupee for INR', () {
        expect(CurrencyUtils.getName('INR'), 'Indian Rupee');
      });

      test('returns US Dollar for USD', () {
        expect(CurrencyUtils.getName('USD'), 'US Dollar');
      });

      test('returns Euro for EUR', () {
        expect(CurrencyUtils.getName('EUR'), 'Euro');
      });

      test('returns British Pound for GBP', () {
        expect(CurrencyUtils.getName('GBP'), 'British Pound');
      });

      test('returns Japanese Yen for JPY', () {
        expect(CurrencyUtils.getName('JPY'), 'Japanese Yen');
      });

      test('returns currency code for unknown', () {
        expect(CurrencyUtils.getName('XYZ'), 'XYZ');
      });
    });

    group('getDecimalPlaces', () {
      test('returns 2 for INR', () {
        expect(CurrencyUtils.getDecimalPlaces('INR'), 2);
      });

      test('returns 2 for USD', () {
        expect(CurrencyUtils.getDecimalPlaces('USD'), 2);
      });

      test('returns 2 for EUR', () {
        expect(CurrencyUtils.getDecimalPlaces('EUR'), 2);
      });

      test('returns 0 for JPY', () {
        expect(CurrencyUtils.getDecimalPlaces('JPY'), 0);
      });

      test('returns 2 for unknown', () {
        expect(CurrencyUtils.getDecimalPlaces('XYZ'), 2);
      });
    });

    group('getSmallestUnit', () {
      test('returns 100 for INR (paisa)', () {
        expect(CurrencyUtils.getSmallestUnit('INR'), 100);
      });

      test('returns 100 for USD (cents)', () {
        expect(CurrencyUtils.getSmallestUnit('USD'), 100);
      });

      test('returns 100 for EUR', () {
        expect(CurrencyUtils.getSmallestUnit('EUR'), 100);
      });

      test('returns 1 for JPY (no subdivision)', () {
        expect(CurrencyUtils.getSmallestUnit('JPY'), 1);
      });

      test('returns 100 for unknown', () {
        expect(CurrencyUtils.getSmallestUnit('XYZ'), 100);
      });
    });
  });

  group('CurrencyExtension', () {
    group('toCurrency', () {
      test('formats int as currency', () {
        final result = 10050.toCurrency('INR');
        expect(result, contains('100'));
        expect(result, contains('₹'));
      });

      test('formats zero', () {
        final result = 0.toCurrency('USD');
        expect(result, contains('0'));
        expect(result, contains('\$'));
      });

      test('formats negative amount', () {
        final result = (-10050).toCurrency('INR');
        // Note: format doesn't add sign, it just formats the number
        expect(result, contains('100'));
      });
    });

    group('toCurrencyWithSign', () {
      test('formats positive int with plus sign', () {
        final result = 10050.toCurrencyWithSign('INR');
        expect(result, startsWith('+'));
        expect(result, contains('100'));
      });

      test('formats negative int with minus sign', () {
        final result = (-10050).toCurrencyWithSign('INR');
        expect(result, startsWith('-'));
        expect(result, contains('100'));
      });

      test('formats zero without sign', () {
        final result = 0.toCurrencyWithSign('INR');
        expect(result, isNot(startsWith('+')));
        expect(result, isNot(startsWith('-')));
      });
    });
  });
}
