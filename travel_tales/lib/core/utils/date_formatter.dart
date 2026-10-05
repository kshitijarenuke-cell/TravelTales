import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTripDateRange(DateTime start, DateTime end) {
    final startFormat = DateFormat('d MMM');
    final endFormat = DateFormat('d MMM yyyy');
    return '${startFormat.format(start)} - ${endFormat.format(end)}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  static String formatDayShort(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return '₹ ${formatter.format(amount.round())}';
  }
}
