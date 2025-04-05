import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class ResourceInfoRequest extends ApiRequest {
  final String resourceId;

  const ResourceInfoRequest(this.resourceId);

  @override
  BaseRequest createRequest(ApiClient api) {
    final uri = api.createUriBuilder('/api/v1/fs/info/$resourceId');
    return Request('get', uri.build());
  }
}
