import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class SharedResourcesRequest extends ApiRequest<PhylumAccount> {
  final int? since;

  SharedResourcesRequest({this.since});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/user/shared');
    if (since != null) {
      uri.queryParameters['since'] = since.toString();
    }
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, SharedResourcesResponse.fromResponse);
  }
}
