import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class SearchRequest extends ApiRequest {
  final String query;

  SearchRequest({required this.query});

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/fs/search');
    uri.queryParameters['q'] = query;
    return Request('get', uri.build());
  }
}
