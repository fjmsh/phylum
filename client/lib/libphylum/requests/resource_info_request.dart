import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class ResourceInfoRequest extends ApiRequest<PhylumAccount> {
  final String resourceId;

  const ResourceInfoRequest(this.resourceId);

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/fs/info/$resourceId:');
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, ResourceInfoResponse.fromResponse);
  }
}
