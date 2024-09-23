import 'dart:convert';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';

typedef PhylumApiAction = ApiAction<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount>;
typedef PhylumApiActionQueue = ApiActionQueue<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount>;
typedef PhylumApiActionQueueState = ApiActionQueueState<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount>;
typedef PhylumApiActionStatus = ActionState<PhylumApiResponse, PhylumApiErrorResponse>;
typedef PhylumApiActionStatusError = ActionStateError<PhylumApiResponse, PhylumApiErrorResponse>;

typedef PhylumApiResponse = Map<String, dynamic>;

class PhylumApiErrorResponse {
  final String code;
  final String message;

  PhylumApiErrorResponse._({required this.code, required this.message});

  factory PhylumApiErrorResponse.fromResponseString(String response) {
    final map = (jsonDecode(response) as Map<String, dynamic>?) ?? const {};
    return PhylumApiErrorResponse._(code: map['code'] ?? 'server_error', message: map['msg'] ?? 'Server Error');
  }

  @override
  String toString() {
    return 'PhylumApiErrorResponse ($code - $message)';
  }
}

Future<ApiResponse<PhylumApiResponse, PhylumApiErrorResponse>> transformApiResponse(ApiRequest _, StreamedResponse response) async {
  final body = await response.bodyString();
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final apiResponse = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
    return ApiSuccessResponse(apiResponse);
  }
  return ApiErrorResponse(statusCode: response.statusCode, err: PhylumApiErrorResponse.fromResponseString(body));
}
