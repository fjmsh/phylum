import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceInfo() async {
  if (Platform.isAndroid) {
    final info = await DeviceInfoPlugin().androidInfo;
    final androidVersion = info.version.codename == "REL" ? info.version.release : info.version.codename;
    return '; Android $androidVersion (SDK ${info.version.sdkInt}); ${info.brand} ${info.device}';
  }
  if (Platform.isLinux) {
    final info = await DeviceInfoPlugin().linuxInfo;
    return "; Linux ${info.prettyName}; Unknown";
  }
  if (Platform.isIOS) {
    final info = await DeviceInfoPlugin().iosInfo;
    return "; iOS ${info.systemVersion}; ${info.modelName}";
  }
  if (Platform.isMacOS) {
    final info = await DeviceInfoPlugin().macOsInfo;
    return "; MacOS ${info.osRelease} ${info.majorVersion}.${info.minorVersion}; ${info.modelName}";
  }
  if (Platform.isWindows) {
    final info = await DeviceInfoPlugin().windowsInfo;
    return "; Windows ${info.productName}; Unknown";
  }

  return "; Unknown; Unknown";
}
