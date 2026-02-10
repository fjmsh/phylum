import 'dart:async';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class EditApiKeyRequest extends ApiRequest<PhylumAccount> {
  final String id;
  final String description;

  EditApiKeyRequest({required this.id, required this.description});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/user/keys/edit');
    final request = Request('post', uri.build());
    request.bodyFields = <String, String>{
      'id': id,
      'description': description,
    };

    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) =>
      parseJsonMapResponse(response, EmptyResponse.fromResponse);
}
