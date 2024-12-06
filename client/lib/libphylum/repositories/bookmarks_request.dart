import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class BookmarksRequest extends ApiRequest {
  final int? since;

  BookmarksRequest({this.since});

  @override
  BaseRequest createRequest(ApiClient api) {
    final uri = api.createUriBuilder('/api/v1/my/bookmarks/list');
    if (since != null) {
      uri.queryParameters['since'] = since.toString();
    }
    return Request('get', uri.build());
  }
}
