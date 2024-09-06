import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

QueryExecutor openDatabase({
  required String storageDir,
  required String tmpDir,
  required String name,
}) {
  return LazyDatabase(() async {
    final file = File(p.join(storageDir, '$name.sqlite'));
    sqlite3.tempDirectory = tmpDir;

    return NativeDatabase.createInBackground(file);
  });
}
