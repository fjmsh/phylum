import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/util/time.dart';

class GenerateApiKeyRequest extends ApiRequest {
  final String description;
  final DateTime? expires;
  final List<String> scopes;

  GenerateApiKeyRequest({required this.description, required this.expires, required this.scopes});

  @override
  BaseRequest createRequest(ApiClient api, {Uint8List? data}) {
    final uri = api.createUriBuilder('/api/v1/user/keys/generate');
    final request = Request('post', uri.build());
    final fields = <String, String>{
      'description': description,
      'scopes': scopes.join(','),
    };
    if (expires != null) {
      fields['expires'] = expires!.formatServer();
    }
    request.bodyFields = fields;

    return request;
  }
}
