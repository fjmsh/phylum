part of 'responses.dart';

class ApiKey {
  final String id;
  final DateTime created;
  final DateTime? expires;
  final String description;
  final List<String> scopes;

  ApiKey({
    required this.id,
    required this.created,
    required this.expires,
    required this.description,
    required this.scopes,
  });
}

class ListApiKeysResponse extends PhylumApiSuccessResponse {
  final List<ApiKey> keys;

  ListApiKeysResponse._({required this.keys});

  factory ListApiKeysResponse.fromResponse(List data) {
    final keys = data.cast<Map>().map((map) {
      final k = map.cast<String, dynamic>();
      return ApiKey(
        id: k['id'],
        created: DateTime.fromMillisecondsSinceEpoch(k['created'] * 1000),
        expires: k['expires'] == 0 ? null : DateTime.fromMillisecondsSinceEpoch(k['expires'] * 1000),
        description: k['description'],
        scopes: (k['scopes'] as List).cast<String>(),
      );
    }).toList(growable: false);
    return ListApiKeysResponse._(keys: keys);
  }

  @override
  Future<void> process(PhylumAccount account) => SynchronousFuture(null);
}
