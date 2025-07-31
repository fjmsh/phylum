import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class ResourceContentsRequest extends ApiRequest {
  final String resourceId;
  final String? versionId;
  final bool loadPreview;

  const ResourceContentsRequest(this.resourceId, {this.versionId, this.loadPreview = false});

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/fs/${loadPreview ? 'preview' : 'contents'}/$resourceId:');
    if (versionId != null) {
      uri.queryParameters['version'] = versionId!;
    }
    return Request('get', uri.build());
  }
}
