import 'dart:io';

import 'package:drift/drift.dart';
import 'package:phylum/libphylum/db/resources.dart';

import 'unsupported.dart' if (dart.library.ffi) 'native.dart' if (dart.library.html) 'web.dart';

part 'db.g.dart';

@DriftDatabase(tables: [Resources])
class AppDatabase extends _$AppDatabase {
  static Directory? storageDir;
  static Directory? tmpDir;
  final String id;

  AppDatabase({required this.id}) : super(_openConnection(id));

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        await m.drop(resources);
        await m.createAll();
      });

  Future<void> dropDatabase() async {
    await super.close();
    await deleteDatabase(storageDir: storageDir, id: id);
  }

  static QueryExecutor _openConnection(String id) {
    return openDatabase(storageDir: storageDir, tmpDir: tmpDir, id: id);
  }
}
