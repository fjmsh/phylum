import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

part 'bookmarks.dart';

typedef JsonMapResponseParser = PhylumApiSuccessResponse Function(Map<String, dynamic> data);

Future<ApiResponse> parseJsonMapResponse(StreamedResponse response, JsonMapResponseParser parseResponse) async {
  final body = await response.bodyString();
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final responseMap = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
    return parseResponse(responseMap);
  }
  return parseErrorResponse(body);
}

PhylumApiErrorResponse parseErrorResponse(String body) {
  final map = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
  return PhylumApiErrorResponse(
    httpStatusCode: map['status'] ?? 500,
    code: map['code'] ?? 'server_error',
    message: map['msg'] ?? 'Server Error',
  );
}
