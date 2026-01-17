import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class ListApiKeysRequest extends ApiRequest {
  const ListApiKeysRequest();

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/user/keys/list');
    return Request('get', uri.build());
  }
}
