import 'package:phylum/util/base_uri_web.dart';
import 'package:uri/uri.dart';
import 'package:web/web.dart' as web;

void startOAuthFlow(UriBuilder oAuthUriBuilder, Uri instanceUrl) {
  final redirectBuilder = UriBuilder.fromUri(webAppBaseUri);
  redirectBuilder.path = '/login/oauth';
  oAuthUriBuilder.queryParameters['redirect_uri'] = redirectBuilder.toString();
  oAuthUriBuilder.queryParameters['state'] = instanceUrl.toString();
  web.window.location.href = oAuthUriBuilder.toString();
}
