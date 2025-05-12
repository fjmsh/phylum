import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class ResourceContentsRequest extends ApiRequest {
  final String resourceId;

  const ResourceContentsRequest(this.resourceId);

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/fs/contents/$resourceId:');
    return Request('get', uri.build());
  }
}
