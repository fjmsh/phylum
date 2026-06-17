part of 'responses.dart';

class SharedResourcesResponse extends PhylumApiSuccessResponse {
  final Iterable<ResourceResponse> resources;

  @override
  Future<void> process(PhylumAccount account) async {
    final db = account.db;
    final shared = resources.indexed.map(
      (r) => SharedCompanion.insert(resourceId: r.$2.resource.id, seq: r.$1),
    );
    final publinks = resources
        .map((r) => r.publinks)
        .fold<List<Publink>>([], (acc, e) => acc..addAll(e));
    final orphanedPublinks = Set.of(
      await (db.select(db.publinks)..where(
            (l) =>
                l.root.isIn(resources.map((r) => r.resource.id)) &
                l.id.isNotIn(publinks.map((l) => l.id)),
          ))
          .map((r) => r.id)
          .get(),
    );

    for (final r in resources) {
      r._updateUserPermissions(account);
    }

    await db.batch((batch) {
      batch.insertAll(
        db.resources,
        resources.map((r) => r.resource),
        mode: InsertMode.insertOrReplace,
      );
      batch.deleteAll(db.shared);
      batch.insertAll(db.shared, shared);

      for (final id in orphanedPublinks) {
        batch.update(
          db.publinks,
          PublinksCompanion(root: Value('')),
          where: (o) => o.id.equals(id),
        );
      }
      batch.insertAll(db.publinks, publinks, mode: InsertMode.insertOrReplace);
    });

    final repo = account.datastore.get<Resource>();
    for (final r in resources) {
      await repo.reloadRemoteData(r.resource.id);
    }

    final publinkRepo = account.datastore.get<Publink>();
    for (final id in orphanedPublinks) {
      publinkRepo.reloadRemoteData(id);
    }
    for (final link in publinks) {
      publinkRepo.replaceRemoteData(link.id, link);
    }
  }

  SharedResourcesResponse({required this.resources});

  factory SharedResourcesResponse.fromResponse(Map<String, dynamic> data) {
    final resources = (data["shared"] as List).cast<Map>().map(
      (u) => ResourceResponse.fromResponse(u.cast<String, dynamic>()),
    );
    return SharedResourcesResponse(resources: resources);
  }
}
