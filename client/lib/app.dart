import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/app/action_queue_status_notifier.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:phylum/ui/app/app_logout.dart';
import 'package:phylum/ui/app/nav_history.dart';
import 'package:provider/provider.dart';

class PhylumApp extends StatelessWidget {
  final PhylumAccount account;
  final NavigatorObserver observer;

  late final _appRouter = GoRouter(
    routes: [
      GoRoute(
        name: 'root',
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        name: 'home',
        path: '/home',
        redirect: (context, state) => '/folders/${context.read<PhylumAccount>().userHome}',
      ),
      GoRoute(
        name: 'folder',
        path: '/folders/:id',
        pageBuilder: (context, state) => NoTransitionPage(
          name: state.name,
          key: ValueKey(state.pathParameters['id']),
          child: AppLayout(folderId: state.pathParameters['id']!),
          arguments: state.pathParameters['id'],
        ),
      ),
    ],
    observers: [
      if (!kIsWeb) observer,
    ],
  );

  PhylumApp._({required this.account, required this.observer}) : super(key: ValueKey(account.id));

  static Widget create(PhylumAccount account) => MultiProvider(
        key: ValueKey(account.id),
        providers: [
          StateNotifierProvider<PhylumAccount, AccountState>.value(value: account),
          StateNotifierProvider<PhylumActionQueue, PhylumActionQueueState>.value(value: account.actionQueue),
          StateNotifierProvider<DownloadManager, DownloadManagerState>(create: (context) => DownloadManager(account)),
          StateNotifierProvider<NavHistoryManager, NavHistoryState>.value(value: NavHistoryManager()),
        ],
        builder: (context, child) => ChangeNotifierProvider(
          create: (context) => ActionQueueStatusNotifier(context),
          child: PhylumApp._(
            account: context.read<PhylumAccount>(),
            observer: context.read<NavHistoryManager>().navObserver,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final ready = context.select<AccountState, bool>((state) => state == AccountState.ready);
    if (ready) {
      return MaterialApp.router(
        key: ValueKey(account.id),
        title: 'Phylum',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0x0063a002),
            dynamicSchemeVariant: DynamicSchemeVariant.neutral,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0x0063a002),
            dynamicSchemeVariant: DynamicSchemeVariant.neutral,
            brightness: Brightness.dark,
          ),
        ),
        routerConfig: _appRouter,
        shortcuts: getAppShortcuts(),
      );
    }
    return MaterialApp.router(
      key: ValueKey('${account.id}-notready'),
      title: 'Logging Out | Phylum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)),
      darkTheme: ThemeData.dark(),
      routerConfig: createLogoutRouter(),
      shortcuts: getAppShortcuts(),
    );
  }

  RouterConfig<Object> createLogoutRouter() => GoRouter(
        errorBuilder: (context, state) => const AppLogout(),
        routes: [],
      );
}
