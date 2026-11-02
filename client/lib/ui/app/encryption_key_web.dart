import 'package:web/web.dart' as web;

bool get supportsEncryption => web.window.isSecureContext;
