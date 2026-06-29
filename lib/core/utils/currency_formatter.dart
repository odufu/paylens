import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _nairaFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 2,
  );

  static final NumberFormat _nairaCompactFormat = NumberFormat.compactSimpleCurrency(
    locale: 'en_NG',
  );

  /// Formats a double value to Naira string: ₦209,891.21
  static String format(double amount) {
    return _nairaFormat.format(amount);
  }

  /// Formats a double value to compact Naira string: ₦210K
  static String formatCompact(double amount) {
    // compactSimpleCurrency uses standard currency code. Let's force Naira symbol.
    final compact = _nairaCompactFormat.format(amount);
    if (compact.startsWith('NGN')) {
      return compact.replaceFirst('NGN', '₦');
    }
    return compact;
  }
}
