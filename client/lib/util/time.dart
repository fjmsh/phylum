import 'package:intl/intl.dart';

final _formatTime = DateFormat.jm();
final _formatMonthDate = DateFormat.MMMd();
final _formatYearMonthDate = DateFormat.yMMMd();

final today = DateTime.now();
final lastWeek = DateTime.now().subtract(const Duration(days: 7));

extension Formats on DateTime {
  String formatForDisplay() {
    DateFormat format = _formatYearMonthDate;
    if (year == today.year) {
      if (day == today.day && month == today.month) {
        format = _formatTime;
      } else {
        format = _formatMonthDate;
      }
    }
    return format.format(this);
  }
}
