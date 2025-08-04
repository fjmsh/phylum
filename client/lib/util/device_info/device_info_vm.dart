import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceInfo() async {
  if (Platform.isAndroid) {
    final info = await DeviceInfoPlugin().androidInfo;
    return '${info.brand} ${info.device}';
  }
  if (Platform.isLinux) {
    final info = await DeviceInfoPlugin().linuxInfo;
    return info.prettyName;
  }
  if (Platform.isIOS) {
    final info = await DeviceInfoPlugin().iosInfo;
    return info.modelName;
  }
  if (Platform.isMacOS) {
    final info = await DeviceInfoPlugin().macOsInfo;
    return info.modelName;
  }
  if (Platform.isWindows) {
    final info = await DeviceInfoPlugin().windowsInfo;
    info.productName;
  }

  return "Unknown";
}
