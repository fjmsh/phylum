import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging/logging.dart';

sealed class RequestResult {
  String get title;
  String? get details => null;

  @override
  String toString() => details == null ? title : '$title - $details';
}

class ServerOffline extends RequestResult {
  @override
  String get title => 'Server Unreachable';
}

class ClientError extends RequestResult {
  final String error;

  ClientError({required this.error});

  @override
  String get title => 'Client Error';

  @override
  String get details => error;
}

class ErrorResponse extends RequestResult {
  final String error;

  ErrorResponse({required this.error});

  @override
  String get title => error;
}

class SuccessResponse extends RequestResult {
  final String responseString;

  SuccessResponse({required this.responseString});

  @override
  String get title => 'Success';
}

Future<RequestResult> sendRequest(
  BaseRequest request, {
  String? message,
}) async {
  try {
    final response = await Client().send(request);
    final responseString = await response.stream.bytesToString();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SuccessResponse(responseString: responseString);
    } else {
      return await _getError(responseString);
    }
  } on SocketException {
    return ServerOffline();
  } catch (e, stackTrace) {
    Log.warn(
      'Unknown error to ${request.url.path}',
      e,
      stackTrace,
    );
    return ClientError(error: e.toString());
  }
}

Future<RequestResult> _getError(String responseString) async {
  try {
    final response = jsonDecode(responseString) as Map;
    return ErrorResponse(error: response['msg']);
  } catch (e) {
    Log.warn(
      'Error parsing error response - ${responseString.substring(0, 24)}',
      e,
    );
    return ClientError(error: 'Error parsing error response');
  }
}

Future<String?> sendRequestDialog(
  BuildContext context,
  BaseRequest request, {
  String? message,
}) async {
  final navigator = message == null ? null : Navigator.of(context);
  if (message != null) {
    showProgressDialog(context, barrierDismissible: false, message: message);
  }

  final result = await sendRequest(request);
  navigator?.pop();
  if (result is SuccessResponse) {
    return result.responseString;
  }
  if (context.mounted) {
    showAlertDialog(
      context,
      barrierDismissible: false,
      title: result.title,
      message: result.details,
    );
  }
  return null;
}
