import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

void performLogin(BuildContext context, Uri instanceUri, String email, String password) async {
  showProgressDialog(
    context,
    barrierDismissible: false,
    title: 'Logging in...',
  );

  final builder = UriBuilder.fromUri(instanceUri);
  builder.path = '${builder.path}/api/v1/auth/password';
  final request = MultipartRequest('post', builder.build());
  request.fields['email'] = email;
  request.fields['password'] = password;

  sendRequest(context, 'Logging In', request, (response) async {
    final accountManager = context.read<AccountManager<PhylumAccount>>();
    final account = await PhylumAccount.createFromLoginResponse(instanceUri, response.cast<String, dynamic>());
    accountManager.addAccount(account);
  });
}

void requestPasswordReset(BuildContext context, Uri instanceUrl, String email) async {
  showProgressDialog(context, barrierDismissible: false, title: 'Requesting Password Reset');

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

void sendRequest(BuildContext context, String title, BaseRequest request, Function(Map) successCallback) async {
  showProgressDialog(context, barrierDismissible: false, title: title);

  try {
    final navigator = Navigator.of(context);
    final response = await Client().send(request);
    final responseString = await response.stream.bytesToString();
    final reponse = jsonDecode(responseString) as Map;

    // Dismiss progress dialog
    navigator.pop();
    if (response.statusCode == 200) {
      successCallback(reponse);
    } else {
      if (context.mounted) {
        showAlertDialog(
          context,
          barrierDismissible: false,
          title: 'Error',
          message: reponse['msg'],
        );
      }
    }
  } on SocketException {
    if (context.mounted) {
      Navigator.of(context).pop();
      showAlertDialog(
        context,
        barrierDismissible: false,
        title: 'Error',
        message: 'Unable to reach ${request.url}',
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      showAlertDialog(
        context,
        barrierDismissible: false,
        title: 'Error',
        message: e.toString(),
      );
    }
    rethrow;
  }
}
