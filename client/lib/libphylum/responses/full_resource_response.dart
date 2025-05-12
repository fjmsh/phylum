part of 'responses.dart';

class FullResourceResponse extends PhylumApiSuccessResponse {
  final FullResource resource;
  final Iterable<ResourcesCompanion> ancestors;
  final Iterable<FullResource> children;

  FullResourceResponse({
    required this.resource,
    required this.ancestors,
    required this.children,
  });

  factory FullResourceResponse.fromResponse(Map<String, dynamic> data, String username) {
    final ancestors =
        (data['ancestors'] as List).cast<Map>().map((a) => parseResourceAncestor(a.cast<String, dynamic>()));
    final resource = parseFullResource(
      data['resource'],
      parent: ancestors.isNotEmpty ? ancestors.first.id.value : null,
      username: username,
    );
    final children = (data['children'] as List).cast<Map>().map((c) => parseFullResource(
          c.cast<String, dynamic>(),
          parent: resource.resource.id,
          username: username,
          inheritedPermissions: resource.permissions,
        ));

    return FullResourceResponse(
      resource: resource,
      ancestors: ancestors,
      children: children,
    );
  }

  @override
  Future process(PhylumAccount account) async {
    final db = account.db;

    final fullResources = [resource, ...children];
    final publinks = fullResources.map((r) => r.publinks).fold<List<Publink>>([], (acc, e) => acc..addAll(e));
    final orphanedPubinks = Set.of(await (db.select(db.publinks)
          ..where(
              (l) => l.root.isIn(fullResources.map((r) => r.resource.id)) & l.id.isNotIn(publinks.map((l) => l.id))))
        .map((r) => r.id)
        .get());

    final existing = Set.of(
        await (db.select(db.resources)..where((t) => t.parent.equals(resource.resource.id))).map((r) => r.id).get());
    existing.removeAll(children.map((r) => r.resource.id));
    final removedChildren = List.of(existing, growable: false);

    await db.batch((batch) async {
      for (final id in removedChildren) {
        batch.update(db.resources, ResourcesCompanion(parent: Value(null)), where: (o) => o.id.equals(id));
      }
      batch.insertAllOnConflictUpdate(db.resources, ancestors);
      batch.insert(db.resources, resource.resource, mode: InsertMode.insertOrReplace);
      batch.insertAll(db.resources, children.map((r) => r.resource), mode: InsertMode.insertOrReplace);

      for (final id in orphanedPubinks) {
        batch.update(db.publinks, PublinksCompanion(root: Value('')), where: (o) => o.id.equals(id));
      }
      batch.insertAll(db.publinks, publinks, mode: InsertMode.insertOrReplace);
    });

    final repo = account.datastore.get<Resource>();
    for (final id in removedChildren) {
      await repo.reloadRemoteData(id);
    }
    // Ancestors are partial updates, so they need to be reloaded
    for (final a in ancestors) {
      await repo.reloadRemoteData(a.id.value);
    }
    // This resource and its children are fully parsed, so the incoming object can replace the existing one
    await repo.replaceRemoteData(resource.resource.id, resource.resource);
    for (final c in children) {
      await repo.replaceRemoteData(c.resource.id, c.resource);
    }
  }
}
