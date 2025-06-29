import 'package:uri/uri.dart';
import 'package:url_launcher/url_launcher.dart';

void startOAuthFlow(UriBuilder oauthUriBuilder) {
  oauthUriBuilder.queryParameters['client_type'] = 'native';
  launchUrl(oauthUriBuilder.build());
}
