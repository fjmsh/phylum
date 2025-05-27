import 'dart:io';

import 'package:drift/drift.dart';

import 'db_stub.dart' if (dart.library.ffi) 'db_vm.dart' if (dart.library.js_interop) 'db_wasm.dart';

part 'db.g.dart';

@DriftDatabase(include: {
  'sql/bookmarks.drift',
  'sql/publinks.drift',
  'sql/recents.drift',
  'sql/resources.drift',
  'sql/shared.drift',
  'sql/trash.drift',
  'sql/users.drift',
})
class AppDatabase extends _$AppDatabase {
  static Directory? storageDir;
  static Directory? tmpDir;
  final String accountId;

  AppDatabase({required this.accountId}) : super(_openConnection(accountId));
  AppDatabase.fromExecutor({required this.accountId, required QueryExecutor executor}) : super(executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) {
          return m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.drop(orderedBookmarks);
            await m.drop(bookmarks);
            await m.create(bookmarks);
            await m.create(orderedBookmarks);
          }
          if (from < 3) {
            await m.drop(resources);
            await m.create(resources);
          }
          if (from < 4) {
            await m.create(trashedResources);
          }
          if (from < 5) {
            await m.drop(resources);
            await m.create(resources);
            await m.create(publinks);
          }
          if (from < 6) {
            await m.drop(resources);
            await m.create(resources);
          }
          if (from < 7) {
            await m.drop(users);
            await m.create(users);
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
