import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Utility class for currency formatting and calculations
/// India-only app - supports only INR (Indian Rupee)
class CurrencyUtils {
  CurrencyUtils._();

  static final _numberFormat = NumberFormat.currency(
    locale: AppConstants.locale,
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  /// Format amount from smallest unit (paisa) to display string
  /// Example: 10050 paisa -> ₹100.50
  static String format(int amountInSmallestUnit) {
    final amount = amountInSmallestUnit / 100;
    return _numberFormat.format(amount);
  }

  /// Format amount with sign (+ or -)
  /// Positive = you're owed, Negative = you owe
  static String formatWithSign(int amountInSmallestUnit) {
    final formatted = format(amountInSmallestUnit.abs());
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

  /// Get currency symbol (always ₹ for India-only app)
  static String getSymbol() => AppConstants.currencySymbol;

  /// Get currency name
  static String getName() => 'Indian Rupee';

  /// Get currency code
  static String getCode() => AppConstants.currency;

  /// Get decimal places for currency (2 for INR)
  static int getDecimalPlaces() => 2;

  /// Get smallest unit for currency (100 paisa = 1 rupee)
  static int getSmallestUnit() => 100;
}

/// Extension on int for easy currency formatting
extension CurrencyExtension on int {
  /// Format this amount (in smallest unit / paisa) as currency
  String toCurrency() {
    return CurrencyUtils.format(this);
  }

  /// Format this amount with sign
  String toCurrencyWithSign() {
    return CurrencyUtils.formatWithSign(this);
  }
}
