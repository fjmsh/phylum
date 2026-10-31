import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:phylum/util/logging/logging.dart';

QueryExecutor openDatabase({
  required Directory? storageDir,
  required Directory? tmpDir,
  required String id,
  required String passphrase,
}) {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: _dbName(id),
        sqlite3Uri: Uri.parse('sqlite3.fbcd2e82.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.191fc9db.js'),
      );

      if (result.missingFeatures.isNotEmpty) {
        // Depending how central local persistence is to your app, you may want
        // to show a warning to the user if only unrealiable implemetentations
        // are available.
        Log.info(
          'Using ${result.chosenImplementation} due to missing browser '
          'features: ${result.missingFeatures}',
        );
      }

      return result.resolvedExecutor;
    }),
  );
}

Future<void> deleteDatabase({
  required Directory? storageDir,
  required String id,
}) async {
  final probe = await WasmDatabase.probe(
    sqlite3Uri: Uri.parse('sqlite3.13d3f11d.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.df0066e7.js'),
    databaseName: _dbName(id),
  );
  for (final db in probe.existingDatabases) {
    await probe.deleteDatabase(db);
  }
}

String _dbName(String id) {
  return '$id-phylum.db';
}
