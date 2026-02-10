import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class EditUserNameRequest extends ApiRequest<PhylumAccount> {
  final String name;

  const EditUserNameRequest(this.name);

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUri('/api/v1/user/profile');
    return MultipartRequest('post', uri)..fields['name'] = name;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, UserResponse.fromResponse);
  }
}
