import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class RevokeApiKeyRequest extends ApiRequest {
  final String id;
  final bool delete;

  RevokeApiKeyRequest({required this.id, required this.delete});

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/user/keys/revoke');
    final request = Request('post', uri.build());
    request.bodyFields = <String, String>{
      'id': id,
      'delete': delete.toString(),
    };

    return request;
  }
}
