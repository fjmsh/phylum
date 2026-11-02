import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/util/random_bytes.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/app/theme.dart';
import 'package:phylum/ui/app/theme_mode_provider.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:provider/provider.dart';

import 'dbus.dart';
import 'encryption_key.dart'
    if (dart.library.js_interop) 'encryption_key_web.dart';
import 'single_instance.dart'
    if (dart.library.js_interop) 'single_instance_web.dart';

const _prefsKeyEncryptionKey = 'encryption_key';

class PhylumApp extends StatefulWidget {
  const PhylumApp({super.key});

  @override
  State<PhylumApp> createState() => _PhylumAppState();

  static Future<Widget> create() async {
    List<int>? encryptionKey;
    if (supportsEncryption) {
      final secureStorage = FlutterSecureStorage();
      final encodedKey = await secureStorage.read(key: _prefsKeyEncryptionKey);
      if (encodedKey == null) {
        encryptionKey = Random.secure().nextBytes(32);
        await secureStorage.write(
          key: _prefsKeyEncryptionKey,
          value: base64Url.encode(encryptionKey),
        );
      } else {
        encryptionKey = base64Url.decode(encodedKey);
      }
    }
    final accountManager = createAccountManager(
      encryptionKey: encryptionKey,
      actionQueueFactory: const NoSyncActionQueueFactory(),
    );
    return MultiProvider(
      providers: [
        StateNotifierProvider<
          AccountManager<PhylumAccount>,
          AccountManagerState<PhylumAccount>
        >.value(value: accountManager),
        StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
          create: (context) => ThemeModeNotifier(),
        ),
      ],
      builder: (context, child) => buildSingleInstance(const PhylumApp()),
    );
  }
}

class _PhylumAppState extends State<PhylumApp> {
  late final PhylumRouterDelegate routerDelegate;

  @override
  void initState() {
    super.initState();
    routerDelegate = PhylumRouterDelegate(accountManager: context.read());
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      ensureSingleClientDBus();
    }
    AppLinks().uriLinkStream.listen((uri) async {
      final info = await const PhylumRouteInformationParser()
          .parseRouteInformation(RouteInformation(uri: uri));
      Log.fine('Opening link $uri');
      routerDelegate.setNewRoutePath(info);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: routerDelegate),
        if (!kIsWeb)
          ChangeNotifierProvider<DownloadManager>(
            create: (context) => DownloadManager(),
          ),
      ],
      builder: (context, child) {
        // return const PhylumApp();
        return MaterialApp.router(
          title: 'Phylum',
          debugShowCheckedModeBanner: false,
          theme: PhylumTheme.light,
          darkTheme: PhylumTheme.dark,
          themeMode: context.watch<ThemeMode>(),
          routeInformationParser: const PhylumRouteInformationParser(),
          routerDelegate: routerDelegate,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
            SingleActivator(LogicalKeyboardKey.tab, shift: true):
                PreviousFocusIntent(),
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
        );
      },
    );
  }
}
