import 'dart:io';

import 'package:drift/drift.dart';

import 'unsupported.dart' if (dart.library.ffi) 'native.dart' if (dart.library.html) 'web.dart';

part 'db.g.dart';

@DriftDatabase(include: {
  'sql/bookmarks.drift',
  'sql/resources.drift',
  'sql/users.drift',
})
class AppDatabase extends _$AppDatabase {
  static Directory? storageDir;
  static Directory? tmpDir;
  final String id;
  bool _cleared = false;
  bool get cleared => _cleared;

  AppDatabase({required this.id}) : super(_openConnection(id));

  @override
  int get schemaVersion => 27;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) {
          _cleared = true;
          return m.createAll();
        },
        onUpgrade: (m, from, to) async {
          _cleared = true;
          await m.drop(resources);
          await m.drop(users);
          await m.drop(bookmarks);
          await m.createAll();
        },
      );

  Future<void> dropDatabase() async {
    await super.close();
    await deleteDatabase(storageDir: storageDir, id: id);
  }

  static QueryExecutor _openConnection(String id) {
    return openDatabase(storageDir: storageDir, tmpDir: tmpDir, id: id);
  }
}
