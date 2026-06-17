import 'package:flutter/foundation.dart';
import 'package:ua_parser/ua_parser.dart';
import 'package:web/web.dart' as html;

Future<String> getDeviceInfo() {
  final nav = html.window.navigator;
  final userAgent = UaParser.parse(nav.userAgent);
  String device = 'Unknown Device';
  if (userAgent.os.name != null) {
    device = userAgent.os.name!;
  }

  if (userAgent.device.model != null) {
    device = userAgent.device.model!;
    if (userAgent.device.vendor != null) {
      device = '${userAgent.device.vendor} $device';
    }
  }

  return SynchronousFuture(
    '${userAgent.browser.name ?? 'Unknown Browser'} on $device',
  );
}
