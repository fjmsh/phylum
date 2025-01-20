part of 'responses.dart';

class PartialResourceResponse extends PhylumApiSuccessResponse {
  final String id;
  final ResourcesCompanion updates;

  @override
  Iterable<(Type, String)> get updatedObjects => [
        (Resource, id),
      ];

  PartialResourceResponse({
    required this.id,
    required this.updates,
  });

  factory PartialResourceResponse.fromResponse(String id, Map<String, dynamic> data) {
    return PartialResourceResponse(
      id: id,
      updates: parsePartialResource(data),
    );
  }

  @override
  Future process(PhylumAccount account) async {
    assert(id == updates.id.value);
    final update = (account.db.resources.update()..where((o) => o.id.equals(id)));
    await update.write(updates);
  }
}
