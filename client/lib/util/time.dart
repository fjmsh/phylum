import 'package:intl/intl.dart';

final _readableFormat = DateFormat.MMMd();

extension ReadableFormat on DateTime {
  String formatReadable() {
    return _readableFormat.format(this);
  }
}
