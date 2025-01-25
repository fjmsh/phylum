part of 'responses.dart';

class PartialResourceResponse extends PhylumApiSuccessResponse {
  final String id;
  final ResourcesCompanion updates;

  PartialResourceResponse({
    required this.id,
    required this.updates,
  });

  factory PartialResourceResponse.fromResponse(Map<String, dynamic> data) {
    final updates = parsePartialResource(data);
    return PartialResourceResponse(
      id: updates.id.value,
      updates: updates,
    );
  }

  @override
  Future process(PhylumAccount account) async {
    assert(id == updates.id.value);
    final update = (account.db.resources.update()..where((o) => o.id.equals(id)));
    await update.write(updates);
    await account.datastore.get<Resource>().reloadRemoteData(id);
  }
}
