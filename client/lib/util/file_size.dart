import 'package:intl/intl.dart';

typedef FileSize = int;
final decimalPattern = NumberFormat.decimalPatternDigits(decimalDigits: 1);

extension FileSizeString on FileSize {
  String formatForDisplay() {
    const suffixes = ['B', 'K', 'M', 'G'];
    var sz = toDouble();
    for (var i = 0; i < suffixes.length; i++) {
      if (sz < 1000) {
        return '${i == 0 ? sz.toInt() : _formatSize(sz)}${suffixes[i]}';
      }
      sz /= 1024;
    }
    return '${_formatSize(sz)}T';
  }

  String _formatSize(double size) {
    return size >= 10 ? '${size.toInt()}' : decimalPattern.format(size);
  }
}
