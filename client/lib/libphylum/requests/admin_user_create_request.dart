import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/libphylum/responses/user_details.dart';

class AdminUserCreateRequest extends ApiRequest<PhylumAccount> {
  final String email;
  final String name;
  final String password;
  final bool noSendEmail;
  final bool noCreateHome;

  AdminUserCreateRequest({
    required this.email,
    required this.name,
    required this.password,
    required this.noSendEmail,
    required this.noCreateHome,
  });

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/admin/users/create');
    final request = Request('post', uri.build());
    request.bodyFields = <String, String>{
      'email': email,
      'name': name,
      'password': password,
      'no_create_home': noCreateHome.toString(),
      'no_send_email': noSendEmail.toString(),
    };
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, UserDetails.fromResponse);
  }
}
