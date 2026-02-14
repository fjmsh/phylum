import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/clipboard.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:provider/provider.dart';

import 'account_selector_stub.dart'
    if (dart.library.ffi) 'account_selector_vm.dart'
    if (dart.library.js_interop) 'account_selector_web.dart';

class PhylumApp extends StatefulWidget {
  const PhylumApp({super.key});

  @override
  State<PhylumApp> createState() => _PhylumAppState();
}

class _PhylumAppState extends State<PhylumApp> {
  final PhylumRouterDelegate routerDelegate = PhylumRouterDelegate(builder: (context) => const AccountSelector());
  final AccountManager<PhylumAccount> accountManager = createAccountManager(isPrimary());

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.linux) {
      startDBusClient();
    }
  }

  void startDBusClient() async {
    final sessionClient = DBusClient.session();
    final requestReply =
        await sessionClient.requestName('cloud.phylum.drive.Instance', flags: {DBusRequestNameFlag.doNotQueue});
    if (requestReply == DBusRequestNameReply.primaryOwner) {
      await sessionClient.registerObject(InstanceObject());
    } else if (requestReply == DBusRequestNameReply.exists) {
      print('Instance Already Running');
      final object = DBusRemoteObject(
        sessionClient,
        name: 'cloud.phylum.drive.Instance',
        path: DBusObjectPath('/drive/phylum/cloud/Instance/Object'),
      );

      var value = await object.getProperty('cloud.phylum.drive.Instance', 'Version', signature: DBusSignature('s'));
      var version = value.asString();
      print('Version $version');

      await object.callMethod('cloud.phylum.drive.Instance', 'Show', [], replySignature: DBusSignature(''));
      await sessionClient.close();
      exit(0);
    } else {
      throw StateError('Unsupported DBus Name Request Reply: $requestReply');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          StateNotifierProvider<AccountManager<PhylumAccount>, AccountManagerState<PhylumAccount>>.value(
              value: accountManager),
          ChangeNotifierProvider.value(value: routerDelegate),
          if (!kIsWeb) ChangeNotifierProvider<DownloadManager>(create: (context) => DownloadManager()),
          Provider(create: (context) => CutToClipboard()),
        ],
        builder: (context, child) {
          const seedColor = Color(0xff769e57);
          final theme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              dynamicSchemeVariant: DynamicSchemeVariant.neutral,
            ),
          );
          final darkTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              dynamicSchemeVariant: DynamicSchemeVariant.neutral,
              brightness: Brightness.dark,
            ),
            brightness: Brightness.dark,
          );

          // return const PhylumApp();
          return MaterialApp.router(
            title: 'Phylum',
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: darkTheme,
            routeInformationParser: const PhylumRouteInformationParser(),
            routerDelegate: routerDelegate,
            shortcuts: appShortcuts,
          );
        });
  }
}

class InstanceObject extends DBusObject {
  InstanceObject() : super(DBusObjectPath('/drive/phylum/cloud/Instance/Object'));

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'cloud.phylum.drive.Instance') {
      if (name == 'Version') {
        return DBusGetPropertyResponse(DBusString('0.7'));
      } else {
        return DBusMethodErrorResponse.unknownProperty();
      }
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'cloud.phylum.drive.Instance') {
      if (methodCall.name == 'Show') {
        if (methodCall.signature != DBusSignature('')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        return DBusMethodSuccessResponse([]);
      } else {
        return DBusMethodErrorResponse.unknownMethod();
      }
    } else {
      return DBusMethodErrorResponse.unknownInterface();
    }
  }
}
