import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/parsers/parsers.dart';
import 'package:phylum/libphylum/phylum_account.dart';

part 'bookmark_list_response.dart';
part 'bookmark_response.dart';
part 'full_resource_response.dart';
part 'partial_resource_response.dart';
part 'shared_resources_response.dart';
part 'user_list_response.dart';

typedef JsonMapResponseParser = PhylumApiSuccessResponse Function(Map<String, dynamic> data);

Future<ApiResponse> parseJsonMapResponse(StreamedResponse response, JsonMapResponseParser parseResponse) async {
  final body = await response.bodyString();
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final responseMap = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
    return parseResponse(responseMap);
  }
  return PhylumApiErrorResponse.fromResponseBody(body);
}

abstract class PhylumApiSuccessResponse extends ApiResponse<PhylumAccount> {
  @override
  bool get success => true;

  @override
  String get description => 'Success';

  const PhylumApiSuccessResponse();
}

class PhylumApiErrorResponse extends ApiResponse<PhylumAccount> {
  final int httpStatusCode;
  final String code;
  final String message;

  @override
  String get description => 'Api Error: $message';

  @override
  bool get success => false;

  @override
  Iterable<(Type, String)> get updatedObjects => const [];

  @override
  Future<void> process(PhylumAccount account) => Future.value();

  PhylumApiErrorResponse({required this.httpStatusCode, required this.code, required this.message});

  factory PhylumApiErrorResponse.fromResponseBody(String body) {
    final map = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
    return PhylumApiErrorResponse(
      httpStatusCode: map['status'] ?? 500,
      code: map['code'] ?? 'server_error',
      message: map['msg'] ?? 'Server Error',
    );
  }
}
