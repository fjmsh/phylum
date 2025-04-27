import 'dart:math';
import 'dart:typed_data';

final _random = Random();
const _range = 1 << 32 - 1; // Issue with web

int _lastTimestamp = 0;

final List<String> _byteToHex = List<String>.generate(256, (i) {
  return i.toRadixString(16).padLeft(2, '0');
});

String generateUuid() {
  var buf = Uint8List(16);
  final (ms, seq) = _getV7Time();

  buf[0] = ms >> 40;
  buf[1] = ms >> 32;
  buf[2] = ms >> 24;
  buf[3] = ms >> 16;
  buf[4] = ms >> 8;
  buf[5] = ms;
  buf[6] = 0x70 | ((seq >> 8) & 0x0f);
  buf[7] = seq;

  _populateRandomBytes4(buf, 8, 8);
  buf[8] = 0x80 | (buf[8] & 0x3f);

  return _format(buf);
}

(int, int) _getV7Time() {
  final time = DateTime.now();
  int ms = time.millisecondsSinceEpoch;
  int us = time.microsecond;
  int now = (ms << 10) + us;
  if (ms < _lastTimestamp) {
    now = _lastTimestamp + 1;
    ms = now >> 10;
    us = now & 0x3ff;
  }
  _lastTimestamp = now;

  return (ms, us);
}

_populateRandomBytes4(Uint8List buf, int offset, int count) {
  for (var i = offset; i < offset + count; i += 4) {
    var k = _random.nextInt(_range);
    buf[i] = k;
    buf[i + 1] = k >> 8;
    buf[i + 2] = k >> 16;
    buf[i + 3] = k >> 24;
  }

  return buf;
}

String _format(Uint8List buf) {
  return '${_byteToHex[buf[0]]}${_byteToHex[buf[1]]}'
      '${_byteToHex[buf[2]]}${_byteToHex[buf[3]]}-'
      '${_byteToHex[buf[4]]}${_byteToHex[buf[5]]}-'
      '${_byteToHex[buf[6]]}${_byteToHex[buf[7]]}-'
      '${_byteToHex[buf[8]]}${_byteToHex[buf[9]]}-'
      '${_byteToHex[buf[10]]}${_byteToHex[buf[11]]}'
      '${_byteToHex[buf[12]]}${_byteToHex[buf[13]]}'
      '${_byteToHex[buf[14]]}${_byteToHex[buf[15]]}';
}
