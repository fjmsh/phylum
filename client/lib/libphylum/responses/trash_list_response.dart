part of 'responses.dart';

class TrashListResponse extends PhylumApiSuccessResponse {
  final Iterable<Resource> resources;
  final String? cursor;

  TrashListResponse({
    required this.resources,
    required this.cursor,
  });

  factory TrashListResponse.fromResponse(Map<String, dynamic> data) {
    final resources = (data['resources'] as List).cast<Map>().map((a) => parseFullResource(a.cast<String, dynamic>()));
    final cursor = data['cursor'] as String;

    return TrashListResponse(
      resources: resources,
      cursor: cursor.isEmpty ? null : cursor,
    );
  }

  @override
  Future process(PhylumAccount account) async {
    account.db.resources.insertAll(resources, mode: InsertMode.insertOrReplace);

    final repo = account.datastore.get<Resource>();
    for (final r in resources) {
      await repo.replaceRemoteData(r.id, r);
    }
  }
}
