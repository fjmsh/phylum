import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';

class ResourceRepository {
  final PhylumAccount account;

  ResourceRepository({required this.account});

  Future<ApiResult<PhylumApiResponse, PhylumApiErrorResponse>?> requestResource(String id) async {
    final response = await account.apiClient.sendRequest(ResourceDetailRequest(id));
    if (response is ApiSuccessResponse<PhylumApiResponse, PhylumApiErrorResponse>) {
      await parseResourceDetailsResponse(response.result);
      return null;
    }
    return response;
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
    return account.db.resources.insertOne(ResourcesCompanion.insert(
      id: id,
      name: name,
      parent: Value(parent),
      dir: dir,
      modified: DateTime.now(),
      size: 0,
      etag: "",
      contentType: contentType,
    ));
  }

  Future<int> updateResource(String id, Insertable<Resource> Function($$ResourcesTableUpdateCompanionBuilder o) fn) {
    return account.db.managers.resources.filter((f) => f.id.equals(id)).update(fn);
  }

  Future<int> deleteResource(String id) {
    return account.db.resources.deleteWhere((f) => f.id.equals(id));
  }

  Future parseResourceDetailsResponse(Map<String, dynamic> data) async {
    final db = account.db;
    final details = parseResourceSummaryObject(data['metadata']).copyWith(lastFetch: Value(DateTime.now()));
    final existing = Set.from(await db.managers.resources.filter((f) => f.parent.id.equals(data['metadata']['id'])).map((r) => r.id).get());
    final children = data.containsKey('children')
        ? (data['children'] as List).cast<Map>().map((c) {
            existing.remove(c['id']);
            return parseResourceSummaryObject(c.cast<String, dynamic>());
          })
        : <ResourcesCompanion>[];
    return db.transaction(() async {
      await db.resources.deleteWhere((o) => o.id.isIn(List.from(existing)));
      await db.batch((batch) {
        batch.insertAll(db.resources, [details, ...children], mode: InsertMode.insertOrReplace);
      });
    });
  }

  Future parseResourceSummaryResponse(Map<String, dynamic> data) async {
    return account.db.into(account.db.resources).insert(parseResourceSummaryObject(data), mode: InsertMode.insertOrReplace);
  }

  ResourcesCompanion parseResourceSummaryObject(Map<String, dynamic> data) {
    return ResourcesCompanion.insert(
      id: data['id'],
      parent: Value(data['parent']),
      name: data['name'],
      dir: data['dir'],
      modified: DateTime.parse(data['modified']),
      size: data['size'],
      etag: data['etag'],
      contentType: data['ctype'] ?? '',
    );
  }
}
