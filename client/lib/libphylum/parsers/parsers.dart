import 'dart:convert';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';

part 'bookmarks.dart';

typedef JsonMapResponseParser = PhylumApiSuccessResponse Function(Map<String, dynamic> data);

abstract class PhylumApiSuccessResponse extends ApiResponse {
  @override
  bool get success => true;

  @override
  String get description => 'Success';

  const PhylumApiSuccessResponse();
}

class PhylumApiErrorResponse extends ApiResponse {
  final int httpStatusCode;
  final String code;
  final String message;

  @override
  String get description => 'Api Error: $message';

  @override
  bool get success => false;

  @override
  Iterable<(Type, String)> get updatedObjects => const [];

  PhylumApiErrorResponse._({required this.httpStatusCode, required this.code, required this.message});

  factory PhylumApiErrorResponse.fromResponseString(String response) {
    final map = (jsonDecode(response) as Map<String, dynamic>?) ?? const {};
    return PhylumApiErrorResponse._(
      httpStatusCode: map['status'] ?? 500,
      code: map['code'] ?? 'server_error',
      message: map['msg'] ?? 'Server Error',
    );
  }
}

Future<ApiResponse> parseJsonMapResponse(StreamedResponse response, JsonMapResponseParser parseResponse) async {
  final body = await response.bodyString();
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final responseMap = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
    return parseResponse(responseMap);
  }
  return PhylumApiErrorResponse.fromResponseString(body);
}
