import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:phylum/libphylum/db/resources.dart';

part 'db.g.dart';

@DriftDatabase(tables: [Resources])
class AppDatabase extends _$AppDatabase {
  AppDatabase(String id) : super(_openConnection(id));

  @override
  int get schemaVersion => 1;

  Future insertResources(Iterable<Insertable<Resource>> list) async {
    for (final i in list) {
      print(i);
    }
    await batch((batch) {
      batch.insertAll(resources, list, mode: InsertMode.insertOrReplace);
    });
  }

  static QueryExecutor _openConnection(String id) {
    // TODO: Don't depend on flutter
    return driftDatabase(name: 'phylum-$id.db');
  }
}
