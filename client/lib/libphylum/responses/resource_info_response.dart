part of 'responses.dart';

class ResourceInfoResponse extends PhylumApiSuccessResponse {
  final ResourceResponse root;
  final Iterable<ResourcesCompanion> ancestors;
  final Iterable<ResourceResponse>? children;

  ResourceInfoResponse({
    required this.root,
    required this.ancestors,
    required this.children,
  });

  factory ResourceInfoResponse.fromResponse(Map<String, dynamic> data) {
    final ancestors =
        (data['ancestors'] as List).cast<Map>().map((a) => parseResourceAncestor(a.cast<String, dynamic>()));
    final root = ResourceResponse.fromResponse(data['resource']);
    final children = (data['children'] as List?)?.cast<Map>().map((c) => ResourceResponse.fromResponse(
          c.cast<String, dynamic>(),
          parent: root.resource.id,
          inheritedPermissions: root.permissions,
        ));

    return ResourceInfoResponse(
      root: root,
      ancestors: ancestors,
      children: children,
    );
  }

  @override
  Future process(PhylumAccount account) async {
    final db = account.db;

    final resources = [root, ...?children];
    for (final r in resources) {
      r._updateUserPermissions(account);
    }
    final publinks = resources.map((r) => r.publinks).fold<List<Publink>>([], (acc, e) => acc..addAll(e));
    final orphanedPublinks = Set.of(await (db.select(db.publinks)
          ..where((l) => l.root.isIn(resources.map((r) => r.resource.id)) & l.id.isNotIn(publinks.map((l) => l.id))))
        .map((r) => r.id)
        .get());

    final existing =
        Set.of(await (db.select(db.resources)..where((t) => t.parent.equals(root.resource.id))).map((r) => r.id).get());
    existing.removeAll(children?.map((r) => r.resource.id) ?? const []);
    final removedChildren = List.of(existing, growable: false);
    final versions = resources.map((r) => r.versions).fold(<ResourceVersion>[], (acc, e) => acc..addAll(e));

    await db.batch((batch) async {
      for (final id in removedChildren) {
        batch.update(db.resources, ResourcesCompanion(parent: Value(null)), where: (o) => o.id.equals(id));
      }
      batch.insertAllOnConflictUpdate(db.resources, ancestors);
      batch.insertAll(db.resources, resources.map((r) => r.resource), mode: InsertMode.insertOrReplace);
      batch.insertAll(db.resourceVersions, versions, mode: InsertMode.insertOrReplace);

      for (final id in orphanedPublinks) {
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
    for (final r in resources) {
      await repo.replaceRemoteData(r.resource.id, r.resource);
    }

    final versionRepo = account.datastore.get<ResourceVersion>();
    for (final v in versions) {
      await versionRepo.replaceRemoteData(v.id, v);
    }

    final publinkRepo = account.datastore.get<Publink>();
    for (final id in orphanedPublinks) {
      publinkRepo.reloadRemoteData(id);
    }
    for (final link in publinks) {
      publinkRepo.replaceRemoteData(link.id, link);
    }
  }
}

ResourcesCompanion parseResourceAncestor(Map<String, dynamic> data) {
  return ResourcesCompanion(
    id: Value(data['id']),
    name: Value(data['name']),
    dir: Value(true),
    userPermission: Value(data['user_permission']),
  );
}
