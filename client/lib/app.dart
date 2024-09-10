import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:provider/provider.dart';

class PhylumApp extends StatelessWidget {
  final PhylumAccount account;

  PhylumApp({required this.account}) : super(key: ValueKey(account.id));

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: account),
        StateNotifierProvider<ApiActionQueue, ApiActionQueueState>.value(value: account.actionQueue),
        // StateNotifierProvider<NavHistoryManager, NavHistoryState>.value(value: routerConfig.historyManager),
      ],
      child: MaterialApp.router(
        key: ValueKey(account),
        title: 'Phylum',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)),
        darkTheme: ThemeData.dark(),
        routerConfig: createRouter(account),
        shortcuts: getAppShortcuts(),
      ),
    );
  }

  GoRouter createRouter(PhylumAccount account) => GoRouter(
        routes: [
          GoRoute(
            name: 'root',
            path: '/',
            redirect: (context, state) => '/home',
          ),
          GoRoute(
            name: 'home',
            path: '/home',
            pageBuilder: (context, state) => NoTransitionPage(child: AppScaffold(folderId: account.userHome)),
          ),
          GoRoute(
            name: 'folder',
            path: '/folders/:id',
            pageBuilder: (context, state) => NoTransitionPage(child: AppScaffold(folderId: state.pathParameters['id']!)),
          ),
        ],
      );
}
