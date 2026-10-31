import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';

QueryExecutor openDatabase({
  required Directory? storageDir,
  required Directory? tmpDir,
  required String id,
  required String passphrase,
}) {
  final file = _dbFile(storageDir, id);
  sqlite3.tempDirectory = tmpDir!.path;

  return NativeDatabase.createInBackground(
    file,
    setup: (rawDb) {
      assert(_debugCheckHasCipher(rawDb));
      rawDb.execute("PRAGMA key = '$passphrase';");
    },
  );
}

Future<void> deleteDatabase({
  required Directory? storageDir,
  required String id,
}) {
  return _dbFile(storageDir, id).delete();
}

File _dbFile(Directory? storageDir, String id) {
  return File(join(storageDir!.path, '$id-phylum.db'));
}

bool _debugCheckHasCipher(Database database) {
  return database.select('PRAGMA cipher;').isNotEmpty;
}
