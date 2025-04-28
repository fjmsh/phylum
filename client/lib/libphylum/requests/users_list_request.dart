import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class UsersListRequest extends ApiRequest {
  const UsersListRequest();

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/users/list');
    return Request('get', uri.build());
  }
}
