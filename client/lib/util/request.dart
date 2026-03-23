import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging.dart';

Future<String?> sendRequest(
  BuildContext context,
  String message,
  BaseRequest request,
) async {
  final navigator = Navigator.of(context);
  showProgressDialog(context, barrierDismissible: false, message: message);

  try {
    final response = await Client().send(request);
    final responseString = await response.stream.bytesToString();
    navigator.pop();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseString;
    } else {
      if (context.mounted) {
        await _showApiErrorMessage(context, responseString);
      }
      return null;
    }
  } on SocketException {
    navigator.pop();
    if (context.mounted) {
      await showAlertDialog(
        context,
        barrierDismissible: false,
        title: 'Error',
        message: 'Unable to reach ${request.url}',
      );
    }
    return null;
  } catch (e) {
    navigator.pop();
    if (context.mounted) {
      await showAlertDialog(
        context,
        barrierDismissible: false,
        title: 'Error',
        message: e.toString(),
      );
    }
    logger.w('Request error to ${request.url.path}', error: e);
    return null;
  }
}

Future _showApiErrorMessage(BuildContext context, String responseString) async {
  try {
    final response = jsonDecode(responseString) as Map;
    return showAlertDialog(
      context,
      barrierDismissible: false,
      title: 'Error',
      message: response['msg'],
    );
  } catch (e) {
    return showAlertDialog(
      context,
      barrierDismissible: false,
      title: 'Error',
      message: e.toString(),
    );
  }
}
