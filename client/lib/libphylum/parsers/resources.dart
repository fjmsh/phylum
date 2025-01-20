import 'package:drift/drift.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class FullResourceResponse extends PhylumApiSuccessResponse {
  final Resource resource;
  final Iterable<ResourcesCompanion> ancestors;
  final Iterable<Resource> children;
  late final Iterable<String> removedChildren;

  @override
  Iterable<(Type, String)> get updatedObjects => [
        (Resource, resource.id),
        ...ancestors.map((r) => (Resource, r.id.value)),
        ...children.map((r) => (Resource, r.id)),
        ...removedChildren.map((id) => (Resource, id)),
      ];

  FullResourceResponse({
    required this.resource,
    required this.ancestors,
    required this.children,
  });

  factory FullResourceResponse.fromResponse(Map<String, dynamic> data) {
    final resource = _parseFullResource(data['info'])..copyWith(lastRefresh: Value(DateTime.now()));
    final ancestors =
        (data['ancestors'] as List).cast<Map>().map((a) => _parseResourceAncestor(a.cast<String, dynamic>()));
    final children = (data['children'] as List).cast<Map>().map((c) => _parseFullResource(c.cast<String, dynamic>()));

    return FullResourceResponse(
      resource: resource,
      ancestors: ancestors,
      children: children,
    );
  }

  @override
  Future process(PhylumAccount account) async {
    final db = account.db;
    final existing =
        Set.of(await (db.select(db.resources)..where((t) => t.parent.equals(resource.id))).map((r) => r.id).get());
    existing.removeAll(children.map((r) => r.id));
    removedChildren = existing;

    await db.batch((batch) {
      for (final id in removedChildren) {
        batch.update(db.resources, ResourcesCompanion(parent: Value(null)), where: (o) => o.id.equals(id));
      }
      batch.insertAllOnConflictUpdate(db.resources, ancestors);
      batch.insert(db.resources, resource, mode: InsertMode.insertOrReplace);
      batch.insertAll(db.resources, children, mode: InsertMode.insertOrReplace);
    });
  }
}

class PartialResourceResponse extends PhylumApiSuccessResponse {
  final String id;
  final ResourcesCompanion updates;

  @override
  Iterable<(Type, String)> get updatedObjects => [
        (Resource, id),
      ];

  PartialResourceResponse({
    required this.id,
    required this.updates,
  });

  factory PartialResourceResponse.fromResponse(String id, Map<String, dynamic> data) {
    return PartialResourceResponse(
      id: id,
      updates: parsePartialResource(data),
    );
  }

  @override
  Future process(PhylumAccount account) async {
    assert(id == updates.id.value);
    final update = (account.db.resources.update()..where((o) => o.id.equals(id)));
    await update.write(updates);
  }
}

Resource _parseFullResource(Map<String, dynamic> data) {
  return Resource(
    id: data['id'],
    parent: data['parent'],
    name: data['name'],
    dir: data['dir'],
    created: DateTime.parse(data['created']),
    modified: DateTime.parse(data['modified']),
    deleted: data['deleted'] != null,
    contentLength: data['c_len'],
    contentSha256: data['c_sha256'],
    contentType: data['c_type'],
    permissions: data['permissions'].isEmpty ? null : data['permissions'],
    publinks: data['publinks'].isEmpty ? null : data['publinks'],
  );
}

ResourcesCompanion _parseResourceAncestor(Map<String, dynamic> data) {
  return ResourcesCompanion(
      id: Value(data['id']),
      parent: Value(data['parent']),
      name: Value(data['name']),
      dir: Value(true),
      permissions: data['permissions'].isEmpty ? Value(null) : Value(data['permissions']));
}

ResourcesCompanion parsePartialResource(Map<String, dynamic> data, [String? id]) {
  return ResourcesCompanion(
    id: Value(data['id'] ?? id),
    parent: Value.absentIfNull(data['parent']),
    name: Value.absentIfNull(data['name']),
    dir: Value.absentIfNull(data['dir']),
    created: Value.absentIfNull(data.containsKey('created') ? DateTime.parse(data['created']) : null),
    modified: Value.absentIfNull(data.containsKey('modified') ? DateTime.parse(data['modified']) : null),
    deleted: Value.absentIfNull(data.containsKey('deleted') ? data['deleted'] != null : null),
    contentLength: Value.absentIfNull(data['c_len']),
    contentSha256: Value.absentIfNull(data['c_sha256']),
    contentType: Value.absentIfNull(data['c_type']),
    permissions: data.containsKey('permissions')
        ? data['permissions'].isEmpty
            ? Value(null)
            : Value(data['permissions'])
        : Value.absent(),
    publinks: data.containsKey('publinks')
        ? data['publinks'].isEmpty
            ? Value(null)
            : Value(data['publinks'])
        : Value.absent(),
  );
}
