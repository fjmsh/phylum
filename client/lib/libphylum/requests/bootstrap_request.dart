import 'dart:async';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class BootstrapRequest extends ApiRequest<PhylumAccount> {
  final int? since;

  BootstrapRequest({this.since});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/user/bootstrap');
    if (since != null) {
      uri.queryParameters['since'] = since.toString();
    }
    return Request('get', uri.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, BootstrapLoginResponse.fromResponse);
  }
}
