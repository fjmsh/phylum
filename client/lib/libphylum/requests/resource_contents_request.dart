import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class ResourceContentsRequest extends ApiRequest {
  final String resourceId;
  final String? versionId;

  const ResourceContentsRequest(this.resourceId, this.versionId);

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/fs/contents/$resourceId:');
    if (versionId != null) {
      uri.queryParameters['version'] = versionId!;
    }
    return Request('get', uri.build());
  }
}
