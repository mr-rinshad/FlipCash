import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 0,
  );

  static String format(num amount) {
    return _inrFormatter.format(amount);
  }

  static String formatPlain(num amount) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return formatter.format(amount);
  }
}
