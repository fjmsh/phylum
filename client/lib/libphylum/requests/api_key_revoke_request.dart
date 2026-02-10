import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class RevokeApiKeyRequest extends ApiRequest<PhylumAccount> {
  final String id;
  final bool delete;

  RevokeApiKeyRequest({required this.id, required this.delete});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/user/keys/revoke');
    final request = Request('post', uri.build());
    request.bodyFields = <String, String>{
      'id': id,
      'delete': delete.toString(),
    };

    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, EmptyResponse.fromResponse);
  }
}
