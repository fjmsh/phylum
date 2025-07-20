part of 'responses.dart';

class GenerateApiKeyResponse extends PhylumApiSuccessResponse {
  final String keyId;
  final String key;
  final String accessToken;

  GenerateApiKeyResponse._({required this.keyId, required this.key, required this.accessToken});

  factory GenerateApiKeyResponse.fromResponse(Map<String, dynamic> data) {
    return GenerateApiKeyResponse._(
      keyId: data['id'],
      key: data['key'],
      accessToken: data['token'],
    );
  }

  @override
  Future<void> process(PhylumAccount account) => SynchronousFuture(null);
}
