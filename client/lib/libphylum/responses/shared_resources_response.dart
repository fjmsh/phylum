part of 'responses.dart';

class SharedResourcesResponse extends PhylumApiSuccessResponse {
  final Iterable<FullResource> resources;

  @override
  Future<void> process(PhylumAccount account) async {
    final shared = resources.indexed.map((r) => SharedCompanion.insert(resourceId: r.$2.resource.id, seq: r.$1));
    await account.db.batch((batch) {
      batch.insertAll(account.db.resources, resources.map((r) => r.resource));
      batch.deleteAll(account.db.shared);
      batch.insertAll(account.db.shared, shared);
    });

    final repo = account.datastore.get<Resource>();
    for (final r in resources) {
      await repo.reloadRemoteData(r.resource.id);
    }
  }

  SharedResourcesResponse({required this.resources});

  factory SharedResourcesResponse.fromResponse(Map<String, dynamic> data) {
    final resources = (data["shared"] as List).cast<Map>().map((u) => parseFullResource(u.cast<String, dynamic>()));
    return SharedResourcesResponse(resources: resources);
  }
}
