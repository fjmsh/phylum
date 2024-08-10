import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class ResourceDetailRequest extends ApiRequest {
  @override
  get tag => "resourceDetails";

  final String resourceId;

  const ResourceDetailRequest(this.resourceId);

  @override
  BaseRequest createRequest(ApiClient api) {
    final uri = api.createUriBuilder('/v1/resources/details/$resourceId');
    return Request('get', uri.build());
  }
}
