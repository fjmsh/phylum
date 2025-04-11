part of 'responses.dart';

class TrashListResponse extends PhylumApiSuccessResponse {
  final Iterable<Resource> resources;
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
    account.db.batch((batch) {
      batch.insertAll(account.db.resources, resources, mode: InsertMode.insertOrReplace);
      if (clear) {
        batch.deleteAll(account.db.trashedResources);
      }
      batch.insertAll(account.db.trashedResources, resources.map((r) => TrashedResource(id: r.id)),
          mode: InsertMode.insertOrReplace);
    });

    final repo = account.datastore.get<Resource>();
    for (final r in resources) {
      await repo.replaceRemoteData(r.id, r);
    }
  }
}
