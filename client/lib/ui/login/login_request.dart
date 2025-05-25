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
  final builder = UriBuilder.fromUri(instanceUri);

  showProgressDialog(
    context,
    barrierDismissible: false,
    title: 'Logging in...',
  );
  builder.path = '${builder.path}/api/v1/auth/password';
  final request = MultipartRequest('post', builder.build());
  request.fields['email'] = email;
  request.fields['password'] = password;

  try {
    final response = await Client().send(request);
    final responseString = await response.stream.bytesToString();
    final json = jsonDecode(responseString) as Map;

    if (context.mounted) {
      Navigator.of(context).pop();
      if (response.statusCode != 200) {
        showAlertDialog(
          context,
          barrierDismissible: false,
          title: 'Login Error',
          message: json['msg'],
        );
      } else {
        final accountManager = context.read<AccountManager<PhylumAccount>>();
        final account = await PhylumAccount.createFromLoginResponse(instanceUri, json.cast<String, dynamic>());
        accountManager.addAccount(account);
      }
    }
  } on SocketException {
    if (context.mounted) {
      Navigator.of(context).pop();
      showAlertDialog(
        context,
        barrierDismissible: false,
        title: 'Login Error',
        message: 'Unable to reach server',
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      showAlertDialog(
        context,
        barrierDismissible: false,
        title: 'Login Error',
        message: e.toString(),
      );
    }
    rethrow;
  }
}
