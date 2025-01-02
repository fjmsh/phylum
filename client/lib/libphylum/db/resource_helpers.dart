import 'package:drift/drift.dart';
import 'package:phylum/libphylum/db/db.dart';

extension ResourceHelpers on AppDatabase {
  Future<Resource?> getResource(String id) {
    return _selectResource(id).getSingleOrNull();
  }

  Stream<Resource?> watchResource(String id) {
    return _selectResource(id).watchSingleOrNull();
  }

  Future<List<Resource>> getResources(Iterable<String> ids) {
    return _selectResources(ids).get();
  }

  Stream<List<Resource>> watchChildren(String id) {
    return (_selectChildren(id)..orderBy([(u) => OrderingTerm.desc(u.dir), (u) => OrderingTerm.asc(u.name.collate(Collate.noCase))])).watch();
  }

  Stream<List<ParentsResult>> watchParents(String id) {
    return parents(id).watch();
  }

  SimpleSelectStatement<Resources, Resource> _selectResource(String id) {
    return resources.select()..where((f) => f.id.equals(id) & f.deleted.equals(false));
  }

  SimpleSelectStatement<Resources, Resource> _selectChildren(String id) {
    return resources.select()..where((f) => f.parent.equals(id) & f.deleted.equals(false));
  }

  SimpleSelectStatement<Resources, Resource> _selectResources(Iterable<String> ids) {
    return resources.select()..where((f) => f.id.isIn(ids));
  }

  Future<int> createResource(String id, String parent, String name, bool dir) {
    return resources.insertOne(
      ResourcesCompanion.insert(
        id: id,
        name: name,
        parent: Value(parent),
        dir: dir,
        created: Value(DateTime.now()),
        modified: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<int> updateResource(String id, Insertable<Resource> Function($ResourcesUpdateCompanionBuilder o) fn) {
    return managers.resources.filter((f) => f.id.equals(id)).update(fn);
  }

  Future<int> deleteResource(String id) {
    return resources.deleteWhere((f) => f.id.equals(id));
  }
}
