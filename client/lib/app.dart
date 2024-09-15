import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:phylum/ui/app/nav_forward.dart';
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      key: ValueKey(widget.account.id),
      providers: [
        Provider.value(value: widget.account),
        StateNotifierProvider<ApiActionQueue, ApiActionQueueState>.value(value: widget.account.actionQueue),
        StateNotifierProvider<NavForwardManager, NavForwardState>.value(value: historyManager),
        StateNotifierProvider<DownloadManager, DownloadManagerState>(create: (context) => DownloadManager(widget.account))
      ],
      child: MaterialApp.router(
        key: ValueKey(widget.account),
        title: 'Phylum',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)),
        darkTheme: ThemeData.dark(),
        routerConfig: createRouter(widget.account),
        shortcuts: getAppShortcuts(),
      ),
    );
  }

  GoRouter createRouter(PhylumAccount account) => GoRouter(
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
            pageBuilder: (context, state) => NoTransitionPage(
              name: state.name,
              child: AppLayout(folderId: account.userHome),
              arguments: account.userHome,
            ),
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
}
