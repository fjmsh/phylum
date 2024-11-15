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

class PhylumApp extends StatefulWidget {
  final PhylumAccount account;
  final NavigatorObserver observer;

  PhylumApp._({required this.account, required this.observer}) : super(key: ValueKey(account.id));

  static Widget create(PhylumAccount account) => MultiProvider(
        key: ValueKey(account.id),
        providers: [
          StateNotifierProvider<PhylumAccount, AccountState>.value(value: account),
          StateNotifierProvider<PhylumActionQueue, PhylumActionQueueState>.value(value: account.actionQueue),
          StateNotifierProvider<DownloadManager, DownloadManagerState>(create: (context) => DownloadManager(account)),
          StateNotifierProvider<NavHistoryManager, NavHistoryState>(create: (context) => NavHistoryManager()),
          ChangeNotifierProvider(create: (context) => ActionQueueStatusNotifier(account.actionQueue))
        ],
        builder: (context, child) => PhylumApp._(
          account: account,
          observer: context.read<NavHistoryManager>().navObserver,
        ),
      );

  @override
  State<PhylumApp> createState() => _PhylumAppState();
}

class _PhylumAppState extends State<PhylumApp> {
  late final AppLifecycleListener _listener;

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
          child: AppLayout.create(state.pathParameters['id']!),
          arguments: state.pathParameters['id'],
        ),
      ),
    ],
    observers: [
      if (!kIsWeb) widget.observer,
    ],
  );

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: (state) {
      if (state == AppLifecycleState.resumed) {
        widget.account.userRepository.refreshUserList();
      }
    });
  }

  @override
  void dispose() {
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
    if (ready) {
      return MaterialApp.router(
        key: ValueKey(widget.account.id),
        title: 'Phylum',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: theme,
        routerConfig: _appRouter,
        shortcuts: getAppShortcuts(),
      );
    }
    return MaterialApp.router(
      key: ValueKey('${widget.account.id}-notready'),
      title: 'Logging Out | Phylum',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      routerConfig: createLogoutRouter(),
    );
  }

  RouterConfig<Object> createLogoutRouter() => GoRouter(
        errorBuilder: (context, state) => const AppLogout(),
        routes: [],
      );
}
