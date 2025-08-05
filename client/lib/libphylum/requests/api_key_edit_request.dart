import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class EditApiKeyRequest extends ApiRequest {
  final String id;
  final String description;

  EditApiKeyRequest({required this.id, required this.description});

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/user/keys/edit');
    final request = Request('post', uri.build());
    request.bodyFields = <String, String>{
      'id': id,
      'description': description,
    };

    return request;
  }
}
