import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

class TestParamsRequest extends ApiRequest<PhylumAccount> {
  final CryptKDF kdf;
  final Map<String, dynamic> params;

  const TestParamsRequest({required this.kdf, required this.params});

  @override
  BaseRequest createRequest(ApiClient api, {Blob? data}) {
    final uri = api.createUriBuilder(
      '/api/v1/admin/config/auth/test/${kdf.name}',
    );

    final request = Request('post', uri.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(params);

    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, TestParamsResponse.fromMap);
  }
}

class TestParamsResponse extends PhylumApiSuccessResponse {
  final Duration? duration;
  final String? error;

  TestParamsResponse._success({required this.duration}) : error = null;

  TestParamsResponse._failure({required this.error}) : duration = null;

  factory TestParamsResponse.fromMap(Map<String, dynamic> data) {
    if (data["success"]) {
      return TestParamsResponse._success(
        duration: Duration(microseconds: data["time"]),
      );
    } else {
      return TestParamsResponse._failure(error: data['error']);
    }
  }

  @override
  Future<void> process(PhylumAccount account) {
    return SynchronousFuture(null);
  }
}
