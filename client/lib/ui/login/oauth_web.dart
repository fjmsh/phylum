import 'package:uri/uri.dart';
import 'package:web/web.dart' as web;

void startOAuthFlow(UriBuilder oauthUriBuilder) {
  oauthUriBuilder.queryParameters['client_type'] = 'web';
  web.window.location.href = oauthUriBuilder.toString();
}
