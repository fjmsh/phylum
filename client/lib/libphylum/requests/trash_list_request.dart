import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class TrashListRequest extends ApiRequest<PhylumAccount> {
  final String? cursor;

  const TrashListRequest({required this.cursor});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/trash/list');
    if (cursor != null) {
      uri.queryParameters['cursor'] = cursor!;
    }
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, TrashListResponse.fromResponse);
  }
}
