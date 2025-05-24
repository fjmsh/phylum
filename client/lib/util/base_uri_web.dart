import 'package:web/web.dart' as web;

Uri? _webAppBaseUri;

Uri get webAppBaseUri => _webAppBaseUri ??= Uri.parse(web.document.baseURI);
