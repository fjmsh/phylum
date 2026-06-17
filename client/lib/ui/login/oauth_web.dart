import 'package:flutter/material.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:uri/uri.dart';
import 'package:web/web.dart' as web;

Future<void> startOAuthFlow(
  BuildContext context,
  UriBuilder oauthUriBuilder,
  String name,
) async {
  showProgressDialog(
    context,
    barrierDismissible: false,
    message: 'Logging in with $name...',
  );
  oauthUriBuilder.queryParameters['client_type'] = 'web';
  web.window.location.href = oauthUriBuilder.toString();
}
