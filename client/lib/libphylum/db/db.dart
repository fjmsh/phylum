import 'dart:io';

import 'package:drift/drift.dart';

import 'db_stub.dart' if (dart.library.ffi) 'db_vm.dart' if (dart.library.html) 'db_wasm.dart';

part 'db.g.dart';

@DriftDatabase(include: {
  'sql/bookmarks.drift',
  'sql/recents.drift',
  'sql/resources.drift',
  'sql/shared.drift',
  'sql/users.drift',
})
class AppDatabase extends _$AppDatabase {
  static Directory? storageDir;
  static Directory? tmpDir;
  final String accountId;

  AppDatabase({required this.accountId}) : super(_openConnection(accountId));
  AppDatabase.fromExecutor({required this.accountId, required QueryExecutor executor}) : super(executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) {
          return m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            m.drop(orderedBookmarks);
            m.drop(bookmarks);
            m.create(bookmarks);
            m.create(orderedBookmarks);
          }
        },
      );

  Future<void> dropDatabase() async {
    await super.close();
    await deleteDatabase(storageDir: storageDir, id: accountId);
  }

  static QueryExecutor _openConnection(String id) {
    return openDatabase(storageDir: storageDir, tmpDir: tmpDir, id: id);
  }
}
