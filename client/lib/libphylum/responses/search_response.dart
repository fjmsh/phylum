part of 'responses.dart';

class SearchResponse extends PhylumApiSuccessResponse {
  final List<Resource> results;

  SearchResponse({required this.results});

  factory SearchResponse.fromResponse(List data) {
    final results = data.cast<Map>().map((u) => parseFullResource(u.cast<String, dynamic>())).toList(growable: false);
    return SearchResponse(results: results);
  }

  @override
  Future process(PhylumAccount account) async {
    await account.db.batch((batch) {
      batch.insertAll(account.db.resources, results, mode: InsertMode.insertOrReplace);
    });
    final repo = account.datastore.get<Resource>();
    for (final r in results) {
      await repo.replaceRemoteData(r.id, r);
    }
  }
}
