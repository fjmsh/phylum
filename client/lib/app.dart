import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:phylum/ui/app/app_logout.dart';
import 'package:phylum/ui/app/nav_forward.dart';
import 'package:phylum/util/logging.dart';
import 'package:provider/provider.dart';

class PhylumApp extends StatefulWidget {
  final PhylumAccount account;

  PhylumApp({required this.account}) : super(key: ValueKey(account.id));

  @override
  State<PhylumApp> createState() => _PhylumAppState();
}

class _PhylumAppState extends State<PhylumApp> {
  final historyManager = NavForwardManager();
  final navigatorKey = GlobalKey<NavigatorState>();

  late final _appRouter = GoRouter(
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(
        name: 'root',
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        name: 'home',
        path: '/home',
        pageBuilder: (context, state) {
          final userHome = context.read<PhylumAccount>().userHome;
          return NoTransitionPage(
            name: state.name,
            child: AppLayout(folderId: userHome),
            arguments: userHome,
          );
        },
      ),
      GoRoute(
        name: 'folder',
        path: '/folders/:id',
        pageBuilder: (context, state) => NoTransitionPage(
          name: state.name,
          child: AppLayout(folderId: state.pathParameters['id']!),
          arguments: state.pathParameters['id'],
        ),
      ),
    ],
    observers: [
      historyManager.navObserver,
    ],
  );

  @override
  void initState() {
    super.initState();
    widget.account.api.addErrorResponseListener((e) {
      if (e.code == "credentials_invalid") {
        logger.i('Invalid Credentials - Logging out');
        context.read<PhylumAccount>().logOut();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      key: ValueKey(widget.account.id),
      providers: [
        StateNotifierProvider<PhylumAccount, AccountState>.value(value: widget.account),
        StateNotifierProvider<ApiActionQueue, ApiActionQueueState>.value(value: widget.account.actionQueue),
        StateNotifierProvider<NavForwardManager, NavForwardState>.value(value: historyManager),
        StateNotifierProvider<DownloadManager, DownloadManagerState>(create: (context) => DownloadManager(widget.account))
      ],
      builder: (context, child) {
        final ready = context.select<AccountState, bool>((state) => state == AccountState.ready);
        if (ready) {
          return MaterialApp.router(
            key: ValueKey(widget.account.id),
            title: 'Phylum',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)),
            darkTheme: ThemeData.dark(),
            routerConfig: _appRouter,
            shortcuts: getAppShortcuts(),
          );
        }
        return MaterialApp.router(
          key: ValueKey('${widget.account.id}-notready'),
          title: 'Phylum',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)),
          darkTheme: ThemeData.dark(),
          routerConfig: createLogoutRouter(),
          shortcuts: getAppShortcuts(),
        );
      },
    );
  }

  RouterConfig<Object> createLogoutRouter() => GoRouter(
        errorBuilder: (context, state) => const AppLogout(),
        routes: [],
      );

  MaterialApp createRouter(RouterConfig<Object> router) => MaterialApp.router(
        key: ValueKey(widget.account),
        title: 'Phylum',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)),
        darkTheme: ThemeData.dark(),
        routerConfig: router,
        shortcuts: getAppShortcuts(),
      );
}
