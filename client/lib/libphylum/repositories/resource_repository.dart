import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';

class ResourceRepository {
  final PhylumAccount account;

  ResourceRepository({required this.account});

  Future<ApiResult> requestResource(String id) async {
    return account.apiClient.sendRequest(ResourceLsRequest(id), callback: (request, response) async {
      if (response is PhylumApiSuccessResponse) {
        await processResourceResponse(response.data);
      }
    });
  }

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

  SimpleSelectStatement<$ResourcesTable, Resource> _selectResource(String id) {
    return account.db.resources.select()..where((f) => f.id.equals(id) & f.deleted.equals(false));
  }

  SimpleSelectStatement<$ResourcesTable, Resource> _selectChildren(String id) {
    return account.db.resources.select()..where((f) => f.parent.equals(id) & f.deleted.equals(false));
  }

  SimpleSelectStatement<$ResourcesTable, Resource> _selectResources(Iterable<String> ids) {
    return account.db.resources.select()..where((f) => f.id.isIn(ids));
  }

  Future<int> createResource(String id, bool dir, String parent, String name, String contentType) {
    return account.db.resources.insertOne(
      ResourcesCompanion.insert(
        id: id,
        name: name,
        parent: Value(parent),
        dir: dir,
        modified: DateTime.now(),
        size: 0,
        sha256: "",
        contentType: contentType,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<int> updateResource(String id, Insertable<Resource> Function($$ResourcesTableUpdateCompanionBuilder o) fn) {
    return account.db.managers.resources.filter((f) => f.id.equals(id)).update(fn);
  }

  Future<int> deleteResource(String id) {
    return account.db.resources.deleteWhere((f) => f.id.equals(id));
  }

  Future processResourceResponse(Map<String, dynamic> data) async {
    final db = account.db;
    final (resources, deleted) = await parseResourceObject(data);
    await db.batch((batch) {
      batch.deleteWhere(db.resources, (o) => o.id.isIn(deleted));
      batch.insertAll(db.resources, resources, mode: InsertMode.insertOrReplace);
    });
  }

  Future<(Iterable<ResourcesCompanion>, Iterable<String>)> parseResourceObject(Map<String, dynamic> data) async {
    bool fullFetch = data.containsKey('children');
    final id = data['id'];
    final details = ResourcesCompanion.insert(
      id: id,
      parent: Value(data['parent']),
      name: data['name'],
      dir: data['dir'],
      modified: DateTime.parse(data['modified']),
      size: data['csize'],
      sha256: data['csha256'],
      contentType: data['ctype'] ?? '',
      deleted: Value(data['deleted'] != null),
      permissions: data['permisisons'] == '{}' ? Value.absent() : Value(data['permisisons']),
      lastFetch: fullFetch ? Value(DateTime.now()) : const Value.absent(),
    );
    final db = account.db;

    if (data.containsKey('children')) {
      final resources = [details];
      final deleted = [];
      final existing = Set.of(await (db.select(db.resources)..where((t) => t.parent.equals(id))).map((r) => r.id).get());
      final children = (data['children'] as List).cast<Map>();
      for (final childData in children) {
        existing.remove(childData['id']);
        final (r, del) = await parseResourceObject(childData.cast<String, dynamic>());
        resources.addAll(r);
        deleted.addAll(del);
      }
      deleted.addAll(existing);
      return (resources, existing);
    } else {
      return ([details], const <String>[]);
    }
  }
}
