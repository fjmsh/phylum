part of 'responses.dart';

class ResourceResponse extends PhylumApiSuccessResponse {
  final Resource resource;
  final Iterable<Publink> publinks;
  final Map<String, Permission> permissions;

  ResourceResponse({required this.resource, required this.publinks, required this.permissions});

  factory ResourceResponse.fromResponse(
    Map<String, dynamic> data, {
    required String username,
    String? parent,
    Map<String, Permission>? inheritedPermissions,
  }) {
    inheritedPermissions ??= (data['inherited_permissions'] as Map).cast<String, Permission>();
    final grants = (data['grants'] as Map)
        .cast<String, Map>()
        .map((k, v) => MapEntry(k, v.cast<String, dynamic>()['p'] as Permission));
    final permissions = Map.of(inheritedPermissions)..addAll(grants);

    final r = Resource(
      id: data['id'],
      parent: parent ?? data['parent'],
      name: data['name'],
      dir: data['dir'],
      created: DateTime.fromMillisecondsSinceEpoch(data['created']),
      modified: DateTime.fromMillisecondsSinceEpoch(data['modified']),
      deleted: data['deleted'] == 0 ? null : DateTime.fromMillisecondsSinceEpoch(data['deleted']),
      contentLength: data['c_len'],
      contentSha256: data['c_sha256'],
      contentType: data['c_type'],
      inheritedPermissions: jsonEncode(inheritedPermissions),
      grants: grants.isEmpty ? null : jsonEncode(grants),
      userPermission: permissions[username] ?? 0,
    );
    final publinks = parsePublinks(data['publinks'], r.id);
    return ResourceResponse(resource: r, publinks: publinks, permissions: permissions);
  }

  @override
  Future process(PhylumAccount account) async {
    final db = account.db;

    final orphanedPubinks = Set.of(await (db.select(db.publinks)
          ..where((l) => l.root.equals(resource.id) & l.id.isNotIn(publinks.map((l) => l.id))))
        .map((r) => r.id)
        .get());

    await db.batch((batch) async {
      batch.insert(db.resources, resource, mode: InsertMode.insertOrReplace);

      for (final id in orphanedPubinks) {
        batch.update(db.publinks, PublinksCompanion(root: Value('')), where: (o) => o.id.equals(id));
      }
      batch.insertAll(db.publinks, publinks, mode: InsertMode.insertOrReplace);
    });

    final repo = account.datastore.get<Resource>();
    await repo.replaceRemoteData(resource.id, resource);
  }
}
