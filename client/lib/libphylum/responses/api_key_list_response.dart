part of 'responses.dart';

class ApiKey {
  final String id;
  final Moment created;
  final Moment? expires;
  final String description;
  final List<String> scopes;
  final LastUsedInfo lastUsed;

  ApiKey({
    required this.id,
    required this.created,
    required this.expires,
    required this.description,
    required this.scopes,
    required this.lastUsed,
  });
}

class LastUsedInfo {
  final int timestamp;
  final String ip;
  final String device;

  LastUsedInfo(this.timestamp, this.ip, this.device);
}

class ListApiKeysResponse extends PhylumApiSuccessResponse {
  final List<ApiKey> keys;

  ListApiKeysResponse._({required this.keys});

  factory ListApiKeysResponse.fromResponse(List data) {
    final keys = data.cast<Map>().map((map) {
      final k = map.cast<String, dynamic>();
      return ApiKey(
        id: k['id'],
        created: Moment.fromMillisecondsSinceEpoch(k['created'] * 1000),
        expires: k['expires'] == 0 ? null : Moment.fromMillisecondsSinceEpoch(k['expires'] * 1000),
        description: k['description'],
        scopes: (k['scopes'] as List).cast<String>(),
        lastUsed: _parseLastUsed((k['last_used'] as Map).cast<String, dynamic>()),
      );
    }).toList(growable: false);
    return ListApiKeysResponse._(keys: keys);
  }

  static LastUsedInfo _parseLastUsed(Map<String, dynamic> data) {
    return LastUsedInfo(data['timestamp'], data['ip'], data['device']);
  }

  @override
  Future<void> process(PhylumAccount account) => SynchronousFuture(null);
}
