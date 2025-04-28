import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class SharedResourcesRequest extends ApiRequest {
  final int? since;

  SharedResourcesRequest({this.since});

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/my/shared');
    if (since != null) {
      uri.queryParameters['since'] = since.toString();
    }
    return Request('get', uri.build());
  }
}
