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
import 'package:phylum/libphylum/explorer/page.dart';
import 'package:provider/provider.dart';

final _appRouter = GoRouter(
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
      builder: (context, state) => AppLayout(page: ExplorerPageFolder(folderId: state.pathParameters['id']!)),
    ),
  ],
);

class PhylumApp extends StatefulWidget {
  const PhylumApp({super.key});

  static Widget create(PhylumAccount account) => MultiProvider(
        key: ValueKey(account.id),
        providers: [
          StateNotifierProvider<PhylumAccount, AccountState>.value(value: account),
          StateNotifierProvider<PhylumActionQueue, PhylumActionQueueState>.value(value: account.actionQueue),
          StateNotifierProvider<DownloadManager, DownloadManagerState>(create: (context) => DownloadManager(account)),
          ChangeNotifierProvider(create: (context) => ActionQueueStatusNotifier(account.actionQueue))
        ],
        child: PhylumApp(),
      );

  @override
  State<PhylumApp> createState() => _PhylumAppState();
}

class _PhylumAppState extends State<PhylumApp> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: (state) {
      if (state == AppLifecycleState.resumed) {
        final account = context.read<PhylumAccount>();
        account.userRepository.refresh();
        account.bookmarkRepository.refresh();
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
        // themeMode: ThemeMode.light,
        routerConfig: _appRouter,
        shortcuts: getAppShortcuts(),
      );
    }
    return MaterialApp.router(
      key: ValueKey('loggingout'),
      title: 'Logging Out | Phylum',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: darkTheme,
      routerConfig: createLogoutRouter(),
    );
  }

  RouterConfig<Object> createLogoutRouter() => GoRouter(
        errorBuilder: (context, state) => const AppLogout(),
        routes: [],
      );
}
