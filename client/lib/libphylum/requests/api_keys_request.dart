import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class ApiKeysRequest extends ApiRequest {
  const ApiKeysRequest();

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/user/keys/list');
    return Request('get', uri.build());
  }
}
