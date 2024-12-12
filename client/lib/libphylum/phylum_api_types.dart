import 'dart:convert';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';

typedef PhylumAction = OfflineAction<PhylumAccount>;
typedef PhylumActionQueue = ApiActionQueue<PhylumAccount>;
typedef PhylumActionQueueState = ApiActionQueueState<PhylumAccount>;

class PhylumApiSuccessResponse extends ApiResponse {
  final Map<String, dynamic> data;

  @override
  String get description => 'Success';

  PhylumApiSuccessResponse(this.data);
}

class PhylumApiErrorResponse extends ApiResponse {
  final int httpStatusCode;
  final String code;
  final String message;

  @override
  String get description => 'Api Error: $message';

  @override
  bool get success => false;

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

Future<ApiResponse> transformApiResponse(ApiRequest _, StreamedResponse response) async {
  final body = await response.bodyString();
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final apiResponse = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
    return PhylumApiSuccessResponse(apiResponse);
  }
  return PhylumApiErrorResponse.fromResponseString(body);
}
