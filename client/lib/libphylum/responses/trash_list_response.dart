part of 'responses.dart';

class TrashListResponse extends PhylumApiSuccessResponse {
  final Iterable<FullResource> resources;
  final String? cursor;
  final bool clear;

  TrashListResponse({
    required this.resources,
    required this.cursor,
    required this.clear,
  });

  factory TrashListResponse.fromResponse(Map<String, dynamic> data) {
    final resources = (data['resources'] as List).cast<Map>().map((a) => parseFullResource(a.cast<String, dynamic>()));
    final cursor = data['cursor'] as String;
    final clear = data['clear'] as bool;

    return TrashListResponse(
      resources: resources,
      cursor: cursor.isEmpty ? null : cursor,
      clear: clear,
    );
  }

  @override
  Future process(PhylumAccount account) async {
    final db = account.db;
    final publinks = resources.map((r) => r.publinks).fold<List<Publink>>([], (acc, e) => acc..addAll(e));
    final orphanedPublinks = Set.of(await (db.select(db.publinks)
          ..where((l) => l.root.isIn(resources.map((r) => r.resource.id)) & l.id.isNotIn(publinks.map((l) => l.id))))
        .map((r) => r.id)
        .get());

    db.batch((batch) {
      batch.insertAll(db.resources, resources.map((r) => r.resource), mode: InsertMode.insertOrReplace);
      if (clear) {
        batch.deleteAll(db.trashedResources);
      }
      batch.insertAll(db.trashedResources, resources.map((r) => TrashedResource(id: r.resource.id)),
          mode: InsertMode.insertOrReplace);
      for (final id in orphanedPublinks) {
        batch.update(db.publinks, PublinksCompanion(root: Value('')), where: (o) => o.id.equals(id));
      }
      batch.insertAll(db.publinks, publinks, mode: InsertMode.insertOrReplace);
    });

    final repo = account.datastore.get<Resource>();
    for (final r in resources) {
      await repo.replaceRemoteData(r.resource.id, r.resource);
    }
  }
}
