import 'dart:convert';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class ValidateMailConfigRequest extends ApiRequest<PhylumAccount> {
  final MailConfig config;
  final String? sendTo;

  const ValidateMailConfigRequest({required this.config, this.sendTo});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder('/api/v1/admin/config/mail/validate');

    final request = Request('post', uri.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'config': config.toMap(),
      if (sendTo != null) 'send_to': sendTo,
    });
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, EmptyResponse.fromResponse);
  }
}
