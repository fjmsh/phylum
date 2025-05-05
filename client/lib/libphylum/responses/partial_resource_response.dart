part of 'responses.dart';

class PartialResourceResponse extends PhylumApiSuccessResponse {
  final String id;
  final PartialResource updates;

  PartialResourceResponse({
    required this.id,
    required this.updates,
  });

  factory PartialResourceResponse.fromResponse(Map<String, dynamic> data) {
    final updates = parsePartialResource(data);
    return PartialResourceResponse(
      id: updates.resource.id.value,
      updates: updates,
    );
  }

  @override
  Future process(PhylumAccount account) async {
    final db = account.db;

    final publinks = updates.publinks;
    Iterable<String>? orphanedPublinks;
    if (publinks != null) {
      orphanedPublinks = Set.of(await (db.select(db.publinks)
            ..where((l) => l.root.equals(id) & l.id.isNotIn(publinks.map((l) => l.id))))
          .map((r) => r.id)
          .get());
    }

    await db.batch((batch) async {
      batch.update(db.resources, updates.resource, where: (o) => o.id.equals(id));
      if (publinks != null) {
        for (final id in orphanedPublinks!) {
          batch.update(db.publinks, PublinksCompanion(root: Value('')), where: (o) => o.id.equals(id));
        }
        batch.insertAll(db.publinks, publinks, mode: InsertMode.insertOrReplace);
      }
    });
    await account.datastore.get<Resource>().reloadRemoteData(id);
  }
}
