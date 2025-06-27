import 'package:web/web.dart' as web;

void startOAuthFlow(Uri oAuthUrl) => web.window.location.href = oAuthUrl.toString();
