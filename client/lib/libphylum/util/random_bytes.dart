import 'dart:math';
import 'dart:typed_data';

extension RandomBytes on Random {
  Uint8List nextBytes(int bytes) {
    final buffer = Uint8List(bytes);
    for (var i = 0; i < bytes; i++) {
      buffer[i] = nextInt(0xFF + 1);
    }
    return buffer;
  }
}
