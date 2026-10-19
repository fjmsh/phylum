import 'dart:convert';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class PasswordUpdateRequest extends ApiRequest<PhylumAccount> {
  final String email;
  final String password;

  PasswordUpdateRequest({required this.email, required this.password});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/admin/user/auth/password/change');
    final request = Request('post', uri.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'email': email, 'new_password': password});
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, EmptyResponse.fromResponse);
  }
}
