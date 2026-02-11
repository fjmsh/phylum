import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> startOAuthFlow(BuildContext context, UriBuilder oauthUriBuilder, String name) async {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logging in with $name')));
  oauthUriBuilder.queryParameters['client_type'] = 'native';
  if (Platform.isLinux) {
    oauthUriBuilder.queryParameters['client_type'] = 'loopback';
    await startLoopbackServer(context);
  }
  launchUrl(oauthUriBuilder.build());
}

Future<void> startLoopbackServer(BuildContext context) async {
  final port = ReceivePort();
  port.listen(createLoopbackRedirectHandler(context));
  await Isolate.spawn(runLoopbackServer, port.sendPort);
}

Function(dynamic) createLoopbackRedirectHandler(BuildContext context) {
  final routerDelegate = context.read<PhylumRouterDelegate>();
  return (dynamic data) {
    if (data is Uri) {
      print('Received callback at $data');
      routerDelegate.go(TokenLoginRoute(
        instanceUrl: data.queryParameters['instance'],
        loginToken: data.queryParameters['token'],
      ));
    }
  };
}

void runLoopbackServer(SendPort sendPort) async {
  const port = 32448;
  final server = await HttpServer.bind('localhost', port);
  print('Listening for oauth redirects');
  server.listen((request) {
    sendPort.send(request.uri);
    request.response.headers.contentType = ContentType.html;
    request.response.write('''
<!DOCTYPE html>
<html>
<head>
<title>Phylum OAuth Redirect</title>
<script>
window.close();
</script>
</head>
</html>
''');
    request.response.close().then((val) {
      server.close(force: true);
    });
  });
}
