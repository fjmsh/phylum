import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/admin_user_list_response.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class AdminUserListRequest extends ApiRequest<PhylumAccount> {
  const AdminUserListRequest();

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/admin/users/list');
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, AdminUserListResponse.fromResponse);
  }
}
