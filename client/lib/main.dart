import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_ce/hive.dart';
import 'package:logger/logger.dart';
import 'package:offtheline/offtheline.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:phylum/libphylum/actions/deserializers.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/logging.dart';

import 'ui/app/app.dart';

import 'util/device_info/device_info_vm.dart' if (dart.library.js_interop) 'util/device_info/device_info_web.dart';

const storageDir = String.fromEnvironment("STORAGE_DIR");

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  logger = Logger(level: Level.info, printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true));
  otlLogger = (LogLevel level, dynamic message, {dynamic error, StackTrace? stackTrace}) {
    final lvl = switch (level) {
      LogLevel.trace => Level.trace,
      LogLevel.debug => Level.debug,
      LogLevel.info => Level.info,
      LogLevel.warning => Level.warning,
      LogLevel.error => Level.error,
      LogLevel.fatal => Level.fatal,
    };
    logger.log(lvl, message, error: error, stackTrace: stackTrace);
  };
  // We use multiple distinct databases for different accounts, so this is expected behavior
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  if (kIsWeb) {
    Hive.init(null, backendPreference: HiveStorageBackendPreference.webWorker);
  } else {
    final appDir = (Platform.isLinux)
        ? Directory(
            path.join((await getApplicationSupportDirectory()).path, storageDir.isNotEmpty ? storageDir : 'data'))
        : await getApplicationDocumentsDirectory();
    AppDatabase.storageDir = appDir;
    blobStorageRoot = appDir.path;
    AppDatabase.tmpDir = await getTemporaryDirectory();

    await appDir.create();
    Hive.init(appDir.path);
  }
  Hive.registerAdapter(OfflineActionAdapter(actionDeserializers));

  PhylumAccount.deviceInfo = await getDeviceInfo();

  runApp(const PhylumApp());
}
