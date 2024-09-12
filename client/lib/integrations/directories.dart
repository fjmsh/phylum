import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class PhylumDirectories {
  late final Directory? tmp;
  late final Directory? downloads;

  static final PhylumDirectories instance = PhylumDirectories._();

  PhylumDirectories._();

  Future<void> initialize() async {
    if (kIsWeb) return;

    final tmpDirectory = await getTemporaryDirectory();
    tmpDirectory.create(recursive: true);
    if (!tmpDirectory.existsSync()) {
      throw 'Unable to create temporary directory';
    }
    tmp = tmpDirectory;

    // final downloadsDirectory = switch() {

    // }
    final downloadsDirectory = await (Platform.isLinux || Platform.isWindows || Platform.isMacOS || Platform.isFuchsia
        ? getDownloadsDirectory()
        : Platform.isAndroid
            ? getExternalStorageDirectory()
            : getApplicationDocumentsDirectory());
    downloadsDirectory!.createSync(recursive: true);
    if (!downloadsDirectory.existsSync()) {
      throw 'Unable to create temporary directory';
    }
    downloads = downloadsDirectory;
  }
}
