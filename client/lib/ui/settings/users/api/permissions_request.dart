import 'dart:convert';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/libphylum/responses/user_details.dart';
import 'package:phylum/libphylum/user_permission.dart';

class PermissionsRequest extends ApiRequest<PhylumAccount> {
  final int userId;
  final List<UserPermission> permissions;

  PermissionsRequest({required this.userId, required this.permissions});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/admin/users/permissions');
    final request = Request('post', uri.build());
    request.body = jsonEncode({'user_id': userId, 'permissions': permissions});
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, UserDetails.fromResponse);
  }
}
