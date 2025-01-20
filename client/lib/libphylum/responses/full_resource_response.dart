part of 'responses.dart';

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
    final resource = parseFullResource(data['info'])..copyWith(lastRefresh: Value(DateTime.now()));
    final ancestors =
        (data['ancestors'] as List).cast<Map>().map((a) => parseResourceAncestor(a.cast<String, dynamic>()));
    final children = (data['children'] as List).cast<Map>().map((c) => parseFullResource(c.cast<String, dynamic>()));

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
