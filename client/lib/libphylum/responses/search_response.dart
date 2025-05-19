part of 'responses.dart';

class SearchResponse extends PhylumApiSuccessResponse {
  final List<ResourceResponse> resources;

  SearchResponse({required this.resources});

  factory SearchResponse.fromResponse(List data) {
    final results =
        data.cast<Map>().map((u) => ResourceResponse.fromResponse(u.cast<String, dynamic>())).toList(growable: false);
    return SearchResponse(resources: results);
  }

  @override
  Future process(PhylumAccount account) async {
    final db = account.db;
    final publinks = resources.map((r) => r.publinks).fold<List<Publink>>([], (acc, e) => acc..addAll(e));
    final orphanedPublinks = Set.of(await (db.select(db.publinks)
          ..where((l) => l.root.isIn(resources.map((r) => r.resource.id)) & l.id.isNotIn(publinks.map((l) => l.id))))
        .map((r) => r.id)
        .get());
    for (final r in resources) {
      r._updateUserPermissions(account);
    }

    await db.batch((batch) {
      batch.insertAll(db.resources, resources.map((r) => r.resource), mode: InsertMode.insertOrReplace);
      for (final id in orphanedPublinks) {
        batch.update(db.publinks, PublinksCompanion(root: Value('')), where: (o) => o.id.equals(id));
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
}
