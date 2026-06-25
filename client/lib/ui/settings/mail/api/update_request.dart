import 'dart:convert';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/config/mail_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class UpdateMailConfigRequest extends ApiRequest<PhylumAccount> {
  final MailConfig config;

  const UpdateMailConfigRequest({required this.config});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/admin/config/mail/update');

    final request = Request('post', uri.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'config': config.toMap()});
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, EmptyResponse.fromResponse);
  }
}
