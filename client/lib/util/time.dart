import 'package:intl/intl.dart';

final _formatTime = DateFormat.jm();
final _formatMonthDate = DateFormat.MMMd();
final _formatYearMonthDate = DateFormat.yMMMd();
final _formatFullNoYear = DateFormat.MMMd().add_jm();
final _formatFull = DateFormat.yMMMd().add_jm();
final _formatNumericDateTime = DateFormat('yyyy-MM-ddTHH:mm:ss');
// final _formatServer = DateFormat('yyyy-MM-ddTHH:mm:ss\'Z\'00:00');

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

extension Formats on DateTime {
  String formatShort() {
    final today = _today;
    if (isAfter(today)) {
      return _formatTime.format(this);
    }
    if (year == today.year) {
      return _formatMonthDate.format(this);
    }
    return _formatYearMonthDate.format(this);
  }

  String formatLong() {
    if (year == _today.year) {
      return _formatFullNoYear.format(this);
    }
    return _formatFull.format(this);
  }

  String formatNumericDateTime() {
    return _formatNumericDateTime.format(this);
  }

  String formatServer() {
    return toUtc().toIso8601String();
  }
}
