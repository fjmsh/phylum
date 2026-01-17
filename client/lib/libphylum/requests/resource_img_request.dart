import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class ResourceImgRequest extends ApiRequest {
  final String resourceId;
  final String? versionId;
  final int imgRes;

  const ResourceImgRequest(this.resourceId, {this.versionId, required this.imgRes});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/fs/img/$resourceId:');
    uri.queryParameters['res'] = imgRes.toString();
    if (versionId != null) {
      uri.queryParameters['version'] = versionId!;
    }
    return Request('get', uri.build());
  }
}
