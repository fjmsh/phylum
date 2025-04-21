import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/ui/app/app_shortcuts.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/app/action_queue_status_notifier.dart';
import 'package:phylum/ui/logout/logout_app.dart';
import 'package:provider/provider.dart';

class PhylumApp extends StatefulWidget {
  const PhylumApp({super.key});

  static Widget create(PhylumAccount account) => MultiProvider(
        key: ValueKey(account.id),
        providers: [
          StateNotifierProvider<PhylumAccount, AccountState>.value(value: account),
          StateNotifierProvider<PhylumActionQueue, PhylumActionQueueState>.value(value: account.actionQueue),
          StateNotifierProvider<DownloadManager, DownloadManagerState>(create: (context) => DownloadManager(account)),
          ChangeNotifierProvider(create: (context) => ActionQueueStatusNotifier(account.actionQueue)),
        ],
        child: PhylumApp(),
      );

  @override
  State<PhylumApp> createState() => _PhylumAppState();
}

class _PhylumAppState extends State<PhylumApp> {
  late final AppLifecycleListener _listener;
  late final PhylumRouterDelegate _routerDelegate;

  @override
  void initState() {
    super.initState();
    _routerDelegate = PhylumRouterDelegate();
    _listener = AppLifecycleListener(onResume: () {
      final account = context.read<PhylumAccount>();
      account.userRepository.refresh();
      account.bookmarkRepository.refresh();
    });
  }

  @override
  void dispose() {
    _routerDelegate.dispose();
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = context.select<AccountState, bool>((state) => state == AccountState.ready);
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
    if (ready) {
      return MaterialApp.router(
        key: ValueKey('ready'),
        title: 'Phylum',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        routeInformationParser: const PhylumRouteInformationParser(),
        routerDelegate: _routerDelegate,
        shortcuts: appShortcuts,
      );
    }
    return const LogoutApp(key: ValueKey('logout'));
  }
}
