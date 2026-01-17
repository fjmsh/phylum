import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class EditUserNameRequest extends ApiRequest {
  final String name;

  const EditUserNameRequest(this.name);

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUri('/api/v1/user/profile');
    return MultipartRequest('post', uri)..fields['name'] = name;
  }
}
