import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';

class TrashListRequest extends ApiRequest {
  final String? cursor;

  const TrashListRequest({required this.cursor});

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/trash/list');
    if (cursor != null) {
      uri.queryParameters['cursor'] = cursor!;
    }
    return Request('get', uri.build());
  }
}
