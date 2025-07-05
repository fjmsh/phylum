import 'package:flutter/material.dart';
import 'package:uri/uri.dart';
import 'package:url_launcher/url_launcher.dart';

void startOAuthFlow(BuildContext context, UriBuilder oauthUriBuilder, String name) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logging in with $name')));
  oauthUriBuilder.queryParameters['client_type'] = 'native';
  launchUrl(oauthUriBuilder.build());
}
