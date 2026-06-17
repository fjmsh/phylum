import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:moment_dart/moment_dart.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/account_user.dart';
import 'package:phylum/libphylum/parsers/parsers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/permissions.dart';

part 'api_key_list_response.dart';
part 'api_key_generate_response.dart';
part 'bookmark_response.dart';
part 'bootstrap_login_response.dart';
part 'empty_response.dart';
part 'publink_response.dart';
part 'resource_info_response.dart';
part 'resource_response.dart';
part 'search_response.dart';
part 'shared_resources_response.dart';
part 'trash_list_response.dart';
part 'user_response.dart';

typedef JsonMapResponseParser =
    PhylumApiSuccessResponse Function(Map<String, dynamic> data);
typedef JsonListResponseParser = PhylumApiSuccessResponse Function(List data);

Future<ApiResponse<PhylumAccount>> parseEmptyResponse(
  StreamedResponse response,
) async {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return const EmptyResponse();
  }
  final body = await response.bodyString();
  return PhylumApiErrorResponse.fromResponseBody(body);
}

Future<ApiResponse<PhylumAccount>> parseJsonMapResponse(
  StreamedResponse response,
  JsonMapResponseParser parseResponse,
) async {
  final body = await response.bodyString();
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final responseMap = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
    return parseResponse(responseMap);
  }
  return PhylumApiErrorResponse.fromResponseBody(body);
}

Future<ApiResponse<PhylumAccount>> parseJsonListResponse(
  StreamedResponse response,
  JsonListResponseParser parseResponse,
) async {
  final body = await response.bodyString();
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final responseMap = (jsonDecode(body) as List?) ?? const [];
    return parseResponse(responseMap);
  }
  return PhylumApiErrorResponse.fromResponseBody(body);
}

typedef PhylumApiSuccessResponse = ApiSuccessResponse<PhylumAccount>;

class PhylumApiErrorResponse extends ApiErrorResponse<PhylumAccount> {
  @override
  final bool serverError;
  final String code;
  final String message;

  @override
  String get description => 'Server Error: $message';

  PhylumApiErrorResponse({
    required this.serverError,
    required this.code,
    required this.message,
  });

  factory PhylumApiErrorResponse.fromResponseBody(String body) {
    final map = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
    final statusCode = map['status'] ?? 500;
    return PhylumApiErrorResponse(
      serverError: statusCode >= 500,
      code: map['code'] ?? 'server_error',
      message: map['msg'] ?? 'Server Error',
    );
  }
}
