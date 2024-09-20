import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class ResourceDetailRequest extends ApiRequest {
  final String resourceId;

  const ResourceDetailRequest(this.resourceId);

  @override
  BaseRequest createRequest(ApiClient api) {
    final uri = api.createUriBuilder('/api/v1/resources/details/$resourceId');
    return Request('get', uri.build());
  }
}
