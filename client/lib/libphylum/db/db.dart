import 'dart:io';

import 'package:drift/drift.dart';

import 'unsupported.dart' if (dart.library.ffi) 'native.dart' if (dart.library.html) 'web.dart';

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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) {
          return m.createAll();
        },
        onUpgrade: (m, from, to) async {},
      );

  Future<void> dropDatabase() async {
    await super.close();
    await deleteDatabase(storageDir: storageDir, id: accountId);
  }

  static QueryExecutor _openConnection(String id) {
    return openDatabase(storageDir: storageDir, tmpDir: tmpDir, id: id);
  }
}
