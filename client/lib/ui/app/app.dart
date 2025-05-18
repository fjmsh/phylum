import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/phylum_account.dart';
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
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          StateNotifierProvider<AccountManager<PhylumAccount>, AccountManagerState<PhylumAccount>>.value(
              value: accountManager),
          ChangeNotifierProvider.value(value: routerDelegate),
          if (!kIsWeb) ChangeNotifierProvider<DownloadManager>(create: (context) => DownloadManager()),
        ],
        builder: (context, child) {
          final theme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color(0xff769e57),
              dynamicSchemeVariant: DynamicSchemeVariant.neutral,
            ),
          );
          final darkTheme = ThemeData(
            colorScheme: theme.colorScheme.copyWith(brightness: Brightness.dark),
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
