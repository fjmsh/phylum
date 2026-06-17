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
import 'dbus.dart';

class PhylumApp extends StatefulWidget {
  const PhylumApp({super.key});

  @override
  State<PhylumApp> createState() => _PhylumAppState();
}

class _PhylumAppState extends State<PhylumApp> {
  final PhylumRouterDelegate routerDelegate = PhylumRouterDelegate(
    builder: (context) => const AccountSelector(),
  );
  final AccountManager<PhylumAccount> accountManager = createAccountManager(
    isPrimary(),
  );

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      ensureSingleClientDBus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StateNotifierProvider<
          AccountManager<PhylumAccount>,
          AccountManagerState<PhylumAccount>
        >.value(value: accountManager),
        ChangeNotifierProvider.value(value: routerDelegate),
        if (!kIsWeb)
          ChangeNotifierProvider<DownloadManager>(
            create: (context) => DownloadManager(),
          ),
        Provider(create: (context) => CutToClipboard()),
      ],
      builder: (context, child) {
        const seedColor = Color(0xff769e57);
        final colorScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          dynamicSchemeVariant: DynamicSchemeVariant.neutral,
        );
        final border = const BorderRadius.all(Radius.circular(8.0));
        final theme = ThemeData(
          colorScheme: colorScheme,
          inputDecorationTheme: InputDecorationThemeData(
            border: OutlineInputBorder(borderRadius: border),
            enabledBorder: OutlineInputBorder(
              borderRadius: border,
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: border,
              borderSide: BorderSide(color: colorScheme.primary, width: 1.0),
            ),
          ),
        );

        // return const PhylumApp();
        return MaterialApp.router(
          title: 'Phylum',
          debugShowCheckedModeBanner: false,
          theme: theme,
          darkTheme: theme.copyWith(brightness: Brightness.dark),
          routeInformationParser: const PhylumRouteInformationParser(),
          routerDelegate: routerDelegate,
          shortcuts: appShortcuts,
        );
      },
    );
  }
}
