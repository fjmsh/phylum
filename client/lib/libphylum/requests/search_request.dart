import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class SearchRequest extends ApiRequest<PhylumAccount> {
  final String query;

  SearchRequest({required this.query});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/fs/search');
    uri.queryParameters['q'] = query;
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonListResponse(response, SearchResponse.fromResponse);
  }
}
