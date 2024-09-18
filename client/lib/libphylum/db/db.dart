import 'package:drift/drift.dart';
import 'package:phylum/libphylum/db/resources.dart';

import 'unsupported.dart' if (dart.library.ffi) 'native.dart' if (dart.library.html) 'web.dart';

part 'db.g.dart';

@DriftDatabase(tables: [Resources])
class AppDatabase extends _$AppDatabase {
  static String storageDir = '';
  static String tmpDir = '';

  AppDatabase(String id) : super(_openConnection(id));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        await m.drop(resources);
        await m.createAll();
      });

  static QueryExecutor _openConnection(String id) {
    return openDatabase(storageDir: storageDir, tmpDir: tmpDir, name: '$id-drift');
  }
}
