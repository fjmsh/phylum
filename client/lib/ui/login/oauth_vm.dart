import 'package:uri/uri.dart';
import 'package:url_launcher/url_launcher.dart';

void startOAuthFlow(UriBuilder oAuthUriBuilder, Uri instanceUrl) {
  final redirectBuilder = UriBuilder.fromUri(instanceUrl);
  // This will redirect to the native scheme cloud.phylum.drive://
  redirectBuilder.path = '/api/v1/auth/oauth_native_redirect';
  oAuthUriBuilder.queryParameters['redirect_uri'] = redirectBuilder.toString();
  launchUrl(oAuthUriBuilder.build());
}
