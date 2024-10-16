import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class ResourceLsRequest extends ApiRequest {
  final String resourceId;

  const ResourceLsRequest(this.resourceId);

  @override
  BaseRequest createRequest(ApiClient api) {
    final uri = api.createUriBuilder('/api/v1/fs/ls/$resourceId');
    return Request('get', uri.build());
  }
}
