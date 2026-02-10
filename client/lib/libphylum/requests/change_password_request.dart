import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class ChangePasswordRequest extends ApiRequest<PhylumAccount> {
  final String email;
  final String oldPassword;
  final String newPassword;

  const ChangePasswordRequest({required this.email, required this.oldPassword, required this.newPassword});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUri('/api/v1/auth/password/change');
    return MultipartRequest('post', uri)
      ..fields['email'] = email
      ..fields['old_password'] = oldPassword
      ..fields['new_password'] = newPassword;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, EmptyResponse.fromResponse);
  }
}
