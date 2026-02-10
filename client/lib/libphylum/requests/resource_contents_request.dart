import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';

class ResourceContentsRequest extends ApiRequest<PhylumAccount> {
  final String resourceId;
  final String? versionId;

  const ResourceContentsRequest(this.resourceId, this.versionId);

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/fs/contents/$resourceId:');
    if (versionId != null) {
      uri.queryParameters['version'] = versionId!;
    }
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) => throw 'Cannot parse contents response';
}
