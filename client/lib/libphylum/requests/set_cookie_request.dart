import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class SetCookieRequest extends ApiRequest {
  const SetCookieRequest();

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/auth/set-cookie');
    return Request('post', uri.build());
  }
}
