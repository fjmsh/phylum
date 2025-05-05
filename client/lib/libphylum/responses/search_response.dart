part of 'responses.dart';

class SearchResponse extends PhylumApiSuccessResponse {
  final List<FullResource> results;

  SearchResponse({required this.results});

  factory SearchResponse.fromResponse(List data) {
    final results = data.cast<Map>().map((u) => parseFullResource(u.cast<String, dynamic>())).toList(growable: false);
    return SearchResponse(results: results);
  }

  @override
  Future process(PhylumAccount account) async {
    final resources = results.map((r) => r.resource);
    await account.db.batch((batch) {
      batch.insertAll(account.db.resources, resources, mode: InsertMode.insertOrReplace);
    });
    final repo = account.datastore.get<Resource>();
    for (final r in resources) {
      await repo.replaceRemoteData(r.id, r);
    }
  }
}
