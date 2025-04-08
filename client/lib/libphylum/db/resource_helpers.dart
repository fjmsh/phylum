import 'package:drift/drift.dart';
import 'package:phylum/libphylum/db/db.dart';

extension ResourceHelpers on AppDatabase {
  Future<Resource?> getResource(String id) {
    return _selectResource(id).getSingleOrNull();
  }

  Future<List<Resource>> getResourcesByName({required String parent, required String name}) {
    return _selectResourceByName(parent: parent, name: name).get();
  }

  Stream<Resource?> watchResource(String id) {
    return _selectResource(id).watchSingleOrNull();
  }

  Future<List<Resource>> getResources(Iterable<String> ids) {
    return _selectResources(ids).get();
  }

  Stream<List<Resource>> watchChildren(String id) {
    return (_selectChildren(id)
          ..orderBy([(u) => OrderingTerm.desc(u.dir), (u) => OrderingTerm.asc(u.name.collate(Collate.noCase))]))
        .watch();
  }

  Stream<List<ParentsResult>> watchParents(String id) {
    return parents(id).watch();
  }

  Stream<PermissionsResult?> watchPermissions(String id) {
    return permissions(id).watchSingleOrNull();
  }

  Future<void> markResourceAccess(String id) {
    return recents.insertOnConflictUpdate(Recent(resourceId: id, accessed: DateTime.now()));
  }

  SimpleSelectStatement<Resources, Resource> _selectResource(String id) {
    return resources.select()..where((f) => f.id.equals(id) & f.deleted.isNull());
  }

  SimpleSelectStatement<Resources, Resource> _selectResourceByName({required String parent, required String name}) {
    return resources.select()..where((f) => f.parent.equals(parent) & f.name.equals(name) & f.deleted.isNull());
  }

  SimpleSelectStatement<Resources, Resource> _selectChildren(String id) {
    return resources.select()..where((f) => f.parent.equals(id) & f.deleted.isNull());
  }

  SimpleSelectStatement<Resources, Resource> _selectResources(Iterable<String> ids) {
    return resources.select()..where((f) => f.id.isIn(ids));
  }
}
