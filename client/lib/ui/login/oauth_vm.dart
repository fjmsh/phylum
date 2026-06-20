import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/login/login_controller.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';
import 'package:url_launcher/url_launcher.dart';

int? loopbackServerPort;

Future<void> startOAuthFlow(
  BuildContext context,
  UriBuilder oauthUriBuilder,
  String name,
) async {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('Logging in with $name')));
  oauthUriBuilder.queryParameters['client_type'] = 'native';
  if (defaultTargetPlatform == TargetPlatform.linux) {
    oauthUriBuilder.queryParameters['client_type'] = 'loopback';
    if (loopbackServerPort == null) {
      await startLoopbackServer(context, oauthUriBuilder);
    } else {
      oauthUriBuilder.queryParameters['loopback_port'] = loopbackServerPort!
          .toString();
      launchUrl(oauthUriBuilder.build());
    }
  } else {
    launchUrl(oauthUriBuilder.build());
  }
}

Future<void> startLoopbackServer(
  BuildContext context,
  UriBuilder oauthUriBuilder,
) async {
  final port = ReceivePort();
  port.listen(createLoopbackRedirectHandler(context, oauthUriBuilder));
  await Isolate.spawn(runLoopbackServer, port.sendPort);
}

Function(dynamic) createLoopbackRedirectHandler(
  BuildContext context,
  UriBuilder oauthUriBuilder,
) {
  final routerDelegate = context.read<PhylumRouterDelegate>();
  return (dynamic data) {
    if (data is int) {
      oauthUriBuilder.queryParameters['loopback_port'] = data.toString();
      launchUrl(oauthUriBuilder.build());
    }
    if (data is Uri) {
      routerDelegate.go(
        LoginRouteConfig(
          instanceUrl: data.queryParameters['instance'],
          loginMethod: TokenLoginMethod(data.queryParameters['token']),
        ),
      );
    }
  };
}

void runLoopbackServer(SendPort sendPort) async {
  final server = await HttpServer.bind('localhost', 0);
  loopbackServerPort = server.port;
  sendPort.send(loopbackServerPort);
  server.listen((request) {
    sendPort.send(request.uri);
    request.response.headers.contentType = ContentType.html;
    request.response.write('''
<!DOCTYPE html>
<html>
<head>
<script>
window.close();
</script>
</head>
</html>
''');
    loopbackServerPort = 0;
    request.response.close().then((val) {
      server.close(force: true);
    });
  });
}
