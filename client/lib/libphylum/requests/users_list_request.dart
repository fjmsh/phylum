import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class UsersListRequest extends ApiRequest {
  const UsersListRequest();

  @override
  BaseRequest createRequest(ApiClient api) {
    final uri = api.createUriBuilder('/api/v1/users/list');
    return Request('get', uri.build());
  }
}
