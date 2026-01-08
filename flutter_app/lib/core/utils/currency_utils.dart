import 'package:intl/intl.dart';

/// Utility class for currency formatting and calculations
class CurrencyUtils {
  CurrencyUtils._();

  /// Format amount from smallest unit (paisa) to display string
  /// Example: 10050 paisa -> ₹100.50
  static String format(int amountInSmallestUnit, String currencyCode) {
    final amount = amountInSmallestUnit / 100;
    final format = _getNumberFormat(currencyCode);
    return format.format(amount);
  }

  /// Format amount with sign (+ or -)
  /// Positive = you're owed, Negative = you owe
  static String formatWithSign(int amountInSmallestUnit, String currencyCode) {
    final formatted = format(amountInSmallestUnit.abs(), currencyCode);
    if (amountInSmallestUnit > 0) {
      return '+$formatted';
    } else if (amountInSmallestUnit < 0) {
      return '-$formatted';
    }
    return formatted;
  }

  /// Parse display string to smallest unit (paisa)
  /// Example: "100.50" -> 10050 paisa
  static int parse(String displayAmount) {
    final cleanAmount = displayAmount.replaceAll(RegExp(r'[^\d.]'), '');
    final parsed = double.tryParse(cleanAmount) ?? 0;
    return (parsed * 100).round();
  }

  /// Get currency symbol
  static String getSymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return currencyCode;
    }
  }

  /// Get currency name
  static String getName(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'INR':
        return 'Indian Rupee';
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'JPY':
        return 'Japanese Yen';
      default:
        return currencyCode;
    }
  }

  /// Get decimal places for currency
  static int getDecimalPlaces(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'JPY':
        return 0;
      default:
        return 2;
    }
  }

  /// Get smallest unit for currency
  static int getSmallestUnit(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'JPY':
        return 1;
      default:
        return 100; // paisa, cents, etc.
    }
  }

  static NumberFormat _getNumberFormat(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'INR':
        return NumberFormat.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 2,
        );
      case 'USD':
        return NumberFormat.currency(
          locale: 'en_US',
          symbol: '\$',
          decimalDigits: 2,
        );
      case 'EUR':
        return NumberFormat.currency(
          locale: 'de_DE',
          symbol: '€',
          decimalDigits: 2,
        );
      case 'GBP':
        return NumberFormat.currency(
          locale: 'en_GB',
          symbol: '£',
          decimalDigits: 2,
        );
      default:
        return NumberFormat.currency(
          symbol: currencyCode,
          decimalDigits: 2,
        );
    }
  }
}

/// Extension on int for easy currency formatting
extension CurrencyExtension on int {
  /// Format this amount (in smallest unit) as currency
  String toCurrency(String currencyCode) {
    return CurrencyUtils.format(this, currencyCode);
  }

  /// Format this amount with sign
  String toCurrencyWithSign(String currencyCode) {
    return CurrencyUtils.formatWithSign(this, currencyCode);
  }
}