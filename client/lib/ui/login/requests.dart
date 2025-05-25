import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

void performLogin(BuildContext context, Uri instanceUri, String email, String password) async {
  final builder = UriBuilder.fromUri(instanceUri);
  builder.path = '${builder.path}/api/v1/auth/password';
  final request = MultipartRequest('post', builder.build());
  request.fields['email'] = email;
  request.fields['password'] = password;

  sendRequest(context, 'Logging In', request, (responseString) async {
    final accountManager = context.read<AccountManager<PhylumAccount>>();
    final navigator = Navigator.of(context);
    showProgressDialog(context, barrierDismissible: false, title: 'Processing Login Response');
    try {
      final response = jsonDecode(responseString) as Map;
      final account = await PhylumAccount.createFromLoginResponse(instanceUri, response.cast<String, dynamic>());
      accountManager.addAccount(account);
    } catch (e) {
      navigator.pop();
      if (context.mounted) {
        showAlertDialog(
          context,
          barrierDismissible: false,
          title: 'Error',
          message: e.toString(),
        );
      }
    }
  });
}

void requestPasswordReset(BuildContext context, Uri instanceUrl, String email) async {
  final builder = UriBuilder.fromUri(instanceUrl);
  builder.path = '${builder.path}/api/v1/auth/request-password-reset';
  final request = MultipartRequest('post', builder.build());
  request.fields['email'] = email;

  sendRequest(context, 'Requesting Password Reset', request, (_) {
    if (context.mounted) {
      showAlertDialog(
        context,
        title: 'Password Reset Requested',
      );
    }
  });
}

void sendRequest(BuildContext context, String title, BaseRequest request, Function(String) successCallback) async {
  final navigator = Navigator.of(context);
  showProgressDialog(context, barrierDismissible: false, title: title);

  late int responseStatusCode;
  late String responseString;
  try {
    final response = await Client().send(request);
    responseStatusCode = response.statusCode;
    responseString = await response.stream.bytesToString();
  } on SocketException {
    navigator.pop();
    if (context.mounted) {
      showAlertDialog(
        context,
        barrierDismissible: false,
        title: 'Error',
        message: 'Unable to reach ${request.url}',
      );
    }
    return;
  } catch (e) {
    navigator.pop();
    if (context.mounted) {
      showAlertDialog(
        context,
        barrierDismissible: false,
        title: 'Error',
        message: e.toString(),
      );
    }
    logger.w('Request error to ${request.url.path}', error: e);
    return;
  }

  // Dismiss progress dialog
  navigator.pop();
  if (responseStatusCode == 200) {
    successCallback(responseString);
  } else {
    if (context.mounted) {
      try {
        final reponse = jsonDecode(responseString) as Map;
        showAlertDialog(
          context,
          barrierDismissible: false,
          title: 'Error',
          message: reponse['msg'],
        );
      } catch (e) {
        if (context.mounted) {
          showAlertDialog(
            context,
            barrierDismissible: false,
            title: 'Error',
            message: e.toString(),
          );
        }
      }
    }
  }
}
