import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:provider/provider.dart';

import 'dbus.dart';
import 'single_instance.dart'
    if (dart.library.js_interop) 'single_instance_web.dart';

class PhylumApp extends StatefulWidget {
  const PhylumApp({super.key});

  @override
  State<PhylumApp> createState() => _PhylumAppState();

  static Widget create() {
    final accountManager = AccountManager(
      (id) => PhylumAccount.restore(id: id),
      autoInitialize: isPrimary(),
    );
    return StateNotifierProvider<
      AccountManager<PhylumAccount>,
      AccountManagerState<PhylumAccount>
    >.value(
      value: accountManager,
      builder: (context, child) => buildSingleInstance(const PhylumApp()),
      child: const PhylumApp(),
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
